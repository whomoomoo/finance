require 'logger'

$logger = Logger.new(STDOUT)
$logger.level = Logger::Severity::INFO
$logger.datetime_format = ""