module.exports = {
  sample:
    regex: /\[(\w*)\]\ (\d{4}-\d{2}-\d{2}) ((.|\r\n)*)/,
    groups: ['', 'severity', 'date', 'content']
    colors: ['', {"ERROR": "red", "INFO": "green", "WARN": "yellow"}, 'blue']
  rails: require './rules/rails'
}
