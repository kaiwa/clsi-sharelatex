async = require "async"
fs = require "fs"
fse = require "fs-extra"
Path = require "path"
logger = require "logger-sharelatex"
_ = require "underscore"

module.exports = OutputCacheManager =
	CACHE_DIR: '.cache/clsi'

	saveOutputFiles: (outputFiles, target, callback) ->
		# make a target/build_id directory and
		# copy all the output files into it
		buildId = 'build-' + Date.now()
		relDir = OutputCacheManager.CACHE_DIR + '/' + buildId
		newDir = target + '/' + relDir
		OutputCacheManager.expireOutputFiles target
		fse.ensureDir newDir, (err) ->
			if err?
				callback(err, outputFiles)
			else
				async.mapSeries outputFiles, (file, cb) ->
					newFile = _.clone(file)
					newFile.path = relDir + '/' + file.path
					src = target + '/' + file.path
					dst = target + '/' + newFile.path
					#console.log 'src', src, 'dst', dst
					fs.stat src, (err, stats) ->
						if err?
							cb(err)
						else if stats.isFile()
							#console.log 'isFile: copying'
							fse.copy src, dst, (err) ->
								cb(err, newFile)
						else
							# other filetype - shouldn't happen
							cb(new Error("output file is not a file"), file)
				, (err, results) ->
					if err?
						callback err, outputFiles
					else
						callback(err, results)

	expireOutputFiles: (target, callback) ->
		# look in target for build dirs and delete if > N or age of mod time > T
		cacheDir = target + '/' + OutputCacheManager.CACHE_DIR
		fs.readdir cacheDir, (err, results) ->
			console.log 'CACHEDIR', results
			callback(err) if callback?