async = require 'async'
fs    = require 'fs-extra'
path  = require 'path'
log   = require('printit')
    prefix: 'Local writer  '

Watcher = require './watcher'


class Local
    constructor: (config, @pouch, @events) ->
        @basePath = config.getDevice().path
        @tmpPath  = path.join @basePath, ".cozy-desktop"
        @watcher  = new Watcher @basePath, @pouch, @events
        @other = null

    start: (mode, done) ->
        fs.ensureDir @basePath, ->
            watcher.start done

    createReadStream: (doc, callback) ->
        callback 'TODO'


    ### Helpers ###

    # Return a function that will update last modification date
    utimesUpdater: (doc, filePath) ->
        (callback) ->
            if doc.lastModification
                lastModification = new Date doc.lastModification
                fs.utimes filePath, new Date(), lastModification, callback
            else
                callback()

    # Check if a file corresponding to given checksum already exists.
    fileExistsLocally: (checksum, callback) =>
        # For legacy binaries
        if not checksum or checksum is ''
            return callback null, false

        @pouch.binaries().get checksum, (err, binaryDoc) =>
            if err
                callback err
            else if not binaryDoc? or binaryDoc.length is 0
                callback null, false
            else if not binaryDoc.path?
                callback null, false
            else
                binaryPath = path.resolve @basePath, binaryDoc.path
                fs.exists binaryPath, (exists) ->
                    if exists
                        callback null, binaryPath
                    else
                        callback null, false


    ### Write operations ###

    # Steps to create a file:
    #   * Checks if the doc is valid: has a path and a name
    #   * Ensure that the temporary directory exists
    #   * Try to find a similar file based on his checksum
    #     (in that case, it just requires a local copy)
    #   * Download the linked binary from remote
    #   * Write to a temporary file
    #   * Ensure parent folder exists
    #   * Move the temporay file to its final destination
    #   * Update creation and last modification dates
    #
    # Note: this method is used for adding a new file
    # or replacing an existing one
    createFile: (doc, callback) =>
        unless doc?.path? and doc?.name? and doc.binary?.file?.id?
            log.warn "The doc is invalid: #{JSON.stringify doc}"
            callback()

        else
            tmpFile  = path.join @tmpPath, doc.path
            parent   = path.resolve @basePath, doc.path
            filePath = path.join parent, doc.name
            binaryId = doc.binary.file.id
            checksum = doc.binary.file.checksum

            async.waterfall [
                (next) =>
                    @fileExistsLocally checksum, next

                (existingFilePath, next) =>
                    # TODO what if existingFilePath is filePath
                    if existingFilePath
                        stream = fs.createReadStream existingFilePath
                        next null, stream
                    else
                        @other.createReadStream doc, next

                # TODO verify the checksum -> remove file if not ok
                # TODO show progress
                (stream, next) =>
                    fs.ensureDir @tmpPath, ->
                        target = fs.createWriteStream tmpFile
                        stream.on 'end', next
                        stream.pipe target

                (next) ->
                    fs.ensureDir parent, ->
                        fs.rename tmpFile, filePath, next

                @utimesUpdater(doc, filePath)

            ], (err) ->
                fs.unlink tmpFile, ->
                    callback err


    # Create a new folder
    createFolder: (doc, callback) =>
        unless doc?.path? and doc?.name?
            log.warn "The doc is invalid: #{JSON.stringify doc}"
            callback()
        else
            folderPath = path.join @basePath, doc.path, doc.name
            fs.ensureDir folderPath, (err) =>
                if err
                    callback err
                else if doc.lastModification?
                    @utimesUpdater(doc, folderPath)(callback)
                else
                    callback()


    # Move a file from one place to another
    # TODO verify checksum
    moveFile: (doc, old, callback) =>
        oldPath = path.join @basePath, old.path, old.name
        newPath = path.join @basePath, doc.path, doc.name
        parent  = path.join @basePath, doc.path

        async.waterfall [
            (next) ->
                fs.exists oldPath, (oldPathExists) ->
                    if oldPathExists
                        fs.ensureDir parent, ->
                            fs.rename oldPath, newPath, next
                    else
                        log.error "File #{oldPath} not found and can't be moved"
                        # TODO createFile
                        next "#{oldPath} not found"

            @utimesUpdater(doc, newPath)

        ], (err) =>
            log.error err
            @createFile doc, callback


    # Move a folder
    moveFolder: (doc, callback) =>
        oldPath = null
        newPath = path.join @basePath, doc.path, doc.name

        async.waterfall [
            (next) =>
                @pouch.getPreviousRev doc, next

            (oldDoc, next) =>
                if oldDoc? and oldDoc.name? and oldDoc.path?
                    oldPath = path.join @basePath, oldDoc.path, oldDoc.name
                    fs.exists oldPath, (oldPathExists) ->
                        next null, oldPathExists
                else
                    next "Can't move, no previous folder known"

            (oldPathExists, next) ->
                if oldPathExists
                    fs.exists newPath, (newPathExists) ->
                        next null, newPathExists
                else
                    next "Folder #{oldPath} not found and can't be moved"

            (newPathExists, next) ->
                if newPathExists
                    # TODO not good!
                    fs.remove newPath, next
                else
                    next()

            (next) ->
                fs.rename oldPath, newPath, next

            @utimesUpdater(doc, newPath)

        ], (err) =>
            log.error err
            @createFolder doc, callback


    # Delete a file from the local filesystem
    deleteFile: (doc, callback) =>
        @pouch.getKnownPath doc, (err, filePath) =>
            if filePath?
                fs.remove path.join(@basePath, filePath), callback
            else
                callback err

    # Delete a folder from the local filesystem
    deleteFolder: (doc, callback) =>
        # For now both operations are similar
        @deleteFile doc, callback

module.exports = Local
