using Dates

header = read("src/header.html", String)
footer = read("src/footer.html", String)

# Handling posts
posts = []
for filename in readdir("src/posts")
    slug, type = split(filename, ".")
    if type == "org"
        data = read("src/posts/$filename", String)
        matches = collect(eachmatch(r"#\+(?<key>.*): (?<value>.*)", data))
        metadata = Dict(match["key"] => match["value"] for match = matches)
        title = metadata["title"]
        date = metadata["date"]
        tags = split(metadata["tags"], ",")
        tags = strip.(tags)
    elseif type == "md"
        data = read("src/posts/$filename", String)
        yaml = match(r"---\n((.|\n)+?)---", data).captures[1]
        yaml = replace(yaml, "[" => "", "]" => "", "\"" => "")
        metas = split(chomp(yaml), "\n")
        metas = split.(metas, ": ", limit = 2)
        metadata = Dict(meta[1] => meta[2] for meta = metas)
        title = metadata["title"]
        date = metadata["date"]
        tags = split(metadata["tags"], ",")
        tags = strip.(tags)
    else
    end
    content = read(`pandoc src/posts/$filename --lua-filter filter.lua`, String)

    post = Dict("slug" => slug, "title" => title, "date" => date, "tags" => tags)
    push!(posts, post)

    template = read("src/templates/post.html", String)
    templated_string = replace(template, "{TITLE}" => title, "{DATE}" => date, "{CONTENT}" => content)
    output = replace(header, "{TITLE}" => title * " - Damien Gonot") * templated_string * footer
    open("build/blog/$slug.html", "w") do io
        write(io, output)
    end
end

# List of blog posts
posts = sort(posts, by = p -> Date(p["date"]), rev = true)
post_link_template = read("src/templates/post-link.html", String)
posts_template = read("src/templates/posts.html", String)
posts_list = [replace(post_link_template, "{TITLE}" => post["title"], "{SLUG}" => post["slug"], "{DATE}" => post["date"]) for post = posts]
content = replace(posts_template, "{CONTENT}" => join(posts_list))
output = replace(header, "{TITLE}" => "Blog Posts - Damien Gonot") * content * footer
open("build/blog.html", "w") do io
    write(io, output)
end

# Other routes
routes = [
    Dict("destination" => "index.html", "source" => "index.html", "title" => "Damien Gonot"),
    Dict("destination" => "about.html", "source" => "about.org", "title" => "About - Damien Gonot"),
]

for route in routes
    destination = route["destination"]
    source = route["source"]
    title = route["title"]

    if endswith(source, ".org")
        local content = read(`pandoc src/$source`, String)
    elseif endswith(source, ".html")
        local content = read("src/$source", String)
    else
    end

    if destination == "index.html"
        local content = replace(content, "{RECENT_BLOG_POSTS}" => join(posts_list[1:5]))
    end

    local output = replace(header, "{TITLE}" => title) * content * footer
    open("build/$destination", "w") do io
        write(io, output)
    end
end

# Wrap it up
println("Website has been generated!")
run(`cp -a src/public/. build/`)
run(`./tailwindcss -i src/input.css -o build/output.css --minify`)
run(`html-minifier --input-dir ./build --output-dir ./build --collapse-whitespace --file-ext html`)
