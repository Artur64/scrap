# Elixir Scrap

 Elixir scrapper task implementation.
## Prerequisities
 [Erlang OTP 22](http://erlang.org/doc/installation_guide/INSTALL.html)+ and [Elixir 1.9.0](https://elixir-lang.org/install.html)

## Setup the project
```
git clone https://github.com/Artur64/scrap
cd scrap
mix deps.get && iex -S mix
```
## Configure it: 

The application is configurable, the possible configurations are: 

1. For underlying parser [Floki](https://github.com/philss/floki)
- `html_parser` - Floki.HTMLParser.FastHtml, but this is completely **optional**!

**NOTE:** in order for parser to work with this parser, please [read](https://github.com/philss/floki#using-fast_html-as-the-html-parser)

2. For the application itself:
- `extraction_template` - Allows a user to set the extraction template, by following format `[{atom(some_key) , string(corresponding_html_tag)}]` - keyword list. 
Where:
  - `atom(some_key)` - An atom, representing a key in result structure, ex. `:assets`
  - `string(corresponding_html_tag)` - A Floki-valid string, which defines `html` tag, ex. `"img"`

This format is used to  define structure, and whole process depends on correctness of the template. By default, the template is set to `[assets: "img", links: "a"]`

## Usage: 
 - `Scrap.fetch(url,append_origin: true)` - `Url` is the requested url, `append_origin: true` will convert all relative paths for images to absolute, by appending requested site location, without that option, `src`'s will have only relative paths.

## Test
Run the tests with `mix test`