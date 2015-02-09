_Adapter_Id = 'PDF'

FS          = require 'fs'
Path        = require 'path'
Winston     = require 'winston'
Metadata    = require 'horace-metadata'
Formats     = require 'horace-formats'
PdfInfo     = require 'pdfinfojs'
_           = require 'lodash'

_Supported_Formats = [Formats.PDF]

_logLevel = 'info'
logger = new Winston.Logger
  transports: [
    new Winston.transports.Console({level: _logLevel}),
    new Winston.transports.File
      filename: "#{_Adapter_Id}.log"
  ]


getHash = (str)->
  unless str
    throw new Error 'Invalid arguments to getHash'

  for i in [0...str.length]
    ch = str.charCodeAt i
    hash = ((hash << 5) - hash) + ch
    hash = hash & hash
  hash.toString()


# Convert (if required) to one of the supported formats
getBook = (metadata, format, nback)->
  if format is Formats.PDF
    # Simple readstream
    nback err, FS.createReadStream(metadata._localPath)

  else
    nback new Error "Adapter (#{_Adapter_Id}) does not support the requested format (#{format})."


# Return an instance of horace-metadata
# (id, localPath, @title, @length, @authors, @subjects, @year, @languages, @publishers, @adapter, @adapterSpecificData)
getMetadata = (path, nback)->
  logger.debug "getMetadata(#{path}, nback)"
  extension = Path.extname path
  unless extension.toLowerCase() is '.pdf'
    nback()
    return

  FS.stat path, (err, stat)->
    if err
      logger.error err
      nback err

    else
      if stat.isFile()
        pdf = new PdfInfo path
        pdf.getInfo (err1, info)->
          if err
            logger.error err1
            nback err1

          else
            # http://www.adobe.com/content/dam/Adobe/en/devnet/acrobat/pdfs/pdf_reference_1-7.pdf
            # TODO: Explore XMP dctionary to see if that has more info
            # Finally, see if publishers etc. can be extracted from the text using NLP
            id = "haopdf_#{getHash path}"
            localPath  = path
            title      = info['title'] or Path.basename path
            length     = info['pages'] or -1
            authors    = (info['author'] or 'Unknown').split ','
            subjects   = (info['subject'] or 'Unknown').split ','
            year       = -1 # Because CreationDate refers to when the PDF file was created, not when the book was written.
            languages  = 'Unknown'
            publishers = 'Unknown'
            adapter    = _Adapter_Id
            nback null, new Metadata(id, localPath, title, length, authors, subjects, year, languages, publishers, adapter, {})


# Update the metadata contained within the pdf file with
# the info in the supplied horace-metadata instance
updateMetadata = (metadata, nback)->
  #TODO : Implement Me!!!
  nback null, metadata

_.extend module.exports,
  id               : _Adapter_Id
  getBook          : getBook
  getMetadata      : getMetadata
  updateMetadata   : updateMetadata
  supportedFormats : _Supported_Formats