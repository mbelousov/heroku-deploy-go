# Go app deployment tool for Heroku
Bash script for [Go](http://golang.org/) app deployment to [Heroku](http://heroku.com/).

===================================
## Usage
This tool should be called from app directory.
(i.e. `GOPATH/src/github.com/mbelousov/demoapp`)

Simply call 
`deploy.sh app_name [procfile] [config] [buildpack]` from your package directory.
### Arguments
  1. `app_name`  - heroku application name
  2. `procfile`  - content of Procfile (optional, use "" to skip)
  3. `config`    - heroku settings (optional, use "" to skip)
  4. `buildpack` - Heroku buildpack (optional, use [heroku-buildpack-go](https://github.com/kr/heroku-buildpack-go) by default)

Order is important.
===================================
## Example:
`deploy.sh demoapp "web: demoapp" "APP_SETTING=VALUE" "https://github.com/mbelousov/heroku-buildpack-go-revel"`

or call `deploy.sh` (without arguments) for help.
