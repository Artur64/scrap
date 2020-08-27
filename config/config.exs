import Config

# Change parser library in order to improve the performance, but requires OS to have C compiler and CMake to be installed
# config :floki, :html_parser, Floki.HTMLParser.FastHtml # Also depends on {:fast_html, "~> 2.0"} in mix.exs

# Set the extraction template, by following format [{ atom(some_key) , string(corresponding_html_tag)}]
# Where:
# corresponding_html_tag - should be valid Floki tag and will be used by Floki to find the given tag.
config :scrap, :extraction_template, assets: "img", links: "a"
