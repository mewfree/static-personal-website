using Dates
using Suppressor

print("Generating website...")

# Clean up first
isdir("build") && rm("build", recursive=true)

header = read("src/header.html", String)
footer = read("src/footer.html", String)

# Handling blog posts
mkpath("build/blog")
posts = []
for filename in readdir("src/posts")
    slug, type = split(filename, ".")
    if type == "org"
        data = read("src/posts/$filename", String)
        matches = collect(eachmatch(r"#\+(?<key>.*): (?<value>.*)", data))
        metadata = Dict(match["key"] => match["value"] for match in matches)
        title = metadata["title"]
        date = metadata["date"]
        tags = split(metadata["tags"], ",")
        tags = strip.(tags)
    elseif type == "md"
        data = read("src/posts/$filename", String)
        yaml = match(r"---\n((.|\n)+?)---", data).captures[1]
        yaml = replace(yaml, "[" => "", "]" => "", "\"" => "")
        metas = split(chomp(yaml), "\n")
        metas = split.(metas, ": ", limit=2)
        metadata = Dict(meta[1] => meta[2] for meta in metas)
        title = metadata["title"]
        date = metadata["date"]
        tags = split(metadata["tags"], ",")
        tags = strip.(tags)
    else
    end
    content = read(`pandoc src/posts/$filename --shift-heading-level-by=1`, String)
    excerpt = read(`pandoc src/posts/$filename -t plain`, String)

    post = Dict("slug" => slug, "title" => title, "date" => date, "tags" => tags)
    push!(posts, post)

    template = read("src/templates/post.html", String)
    templated_string =
        replace(template, "{TITLE}" => title, "{DATE}" => date, "{CONTENT}" => content)
    output =
        replace(
            header,
            "{TITLE}" => title * " - Damien Gonot",
            "{DESCRIPTION}" => "$(first(excerpt, 297))...",
        ) *
        templated_string *
        footer
    open("build/blog/$slug.html", "w") do io
        write(io, output)
    end
end

# List of blog posts
posts = sort(posts, by=p -> Date(p["date"]), rev=true)
post_link_template = read("src/templates/post-link.html", String)
posts_template = read("src/templates/posts.html", String)
posts_list = [
    replace(
        post_link_template,
        "{TITLE}" => post["title"],
        "{SLUG}" => post["slug"],
        "{DATE}" => post["date"],
    ) for post in posts
]
content = replace(posts_template, "{CONTENT}" => join(posts_list))
output =
    replace(
        header,
        "{TITLE}" => "Blog Posts - Damien Gonot",
        "{DESCRIPTION}" => "List of blog posts by Damien Gonot.",
    ) *
    content *
    footer
open("build/blog.html", "w") do io
    write(io, output)
end

# Notes
mkpath("build/notes")
for (root, dirs, files) in walkdir("src/notes")
    for dir in dirs
        path = replace(joinpath(root, dir), "src/" => "build/")
        mkpath(path)
    end
    for file in files
        filename = joinpath(root, file)
        slug, type = split(filename, ".")
        slug = replace(slug, "src/notes/" => "")
        if type == "org"
            local data = read(filename, String)
            local exports_both = map(
                line ->
                    if startswith(line, "#+begin_src") && !contains(line, ":exports")
                return line * " :exports both"
            else
                return line
            end,
                split(data, "\n"),
            )
            local joined = join(["#+options: H:6"; exports_both], "\n")
            local matches = collect(eachmatch(r"#\+(?<key>.*): (?<value>.*)", data))
            local metadata = Dict(match["key"] => match["value"] for match in matches)
            local title = metadata["title"]
            local content = replace(
                read(
                    pipeline(
                        `echo $joined`,
                        `pandoc --quiet --from=org --shift-heading-level-by=1 --mathjax`,
                    ),
                    String,
                ),
                "university.org\">University" => "notes\">Notes",
                "./images/" => "/images/",
                ".org\">" => "\">",
            )
            local excerpt = replace(
                read(
                    pipeline(`echo $joined`, `pandoc --quiet --from=org -t plain`),
                    String,
                ),
                "University" => "Notes",
                r"[^a-zA-Z0-9_\s]" => "",
            )

            local template = read("src/templates/default.html", String)
            local templated_string =
                replace(template, "{TITLE}" => title, "{CONTENT}" => content)
            local output =
                replace(
                    header,
                    "{TITLE}" => title * " - Damien Gonot",
                    "{DESCRIPTION}" => "$(first(excerpt, 297))...",
                ) *
                templated_string *
                footer
            open("build/notes/$slug.html", "w") do io
                write(io, output)
            end
        elseif type == "png"
            run(`cp $filename src/public/images/$file`)
        else
        end
    end
end

# Other routes
routes = [
    (
        destination = "index.html",
        source = "index.html",
        title = "Damien Gonot",
        heading = "",
        description = "Homepage of Damien Gonot's personal website.",
    ),
    (
        destination = "about.html",
        source = "about.org",
        title = "About - Damien Gonot",
        heading = "About me",
        description = "Learn more about Damien Gonot.",
    ),
    (
        destination = "notes.html",
        source = "notes.org",
        title = "Notes - Damien Gonot",
        heading = "Notes",
        description = "Damien Gonot's public notes.",
    ),
]

for route in routes
    (; destination, source, title, heading, description) = route

    if endswith(source, ".org")
        local template = read("src/templates/default.html", String)
        local html = replace(
            read(`pandoc src/$source --shift-heading-level-by=1`, String),
            ".org\">" => "\">",
            "University" => "Notes",
            "university" => "notes",
        )
        local content = replace(template, "{TITLE}" => heading, "{CONTENT}" => html)
    elseif endswith(source, ".html")
        local content = read("src/$source", String)
    else
    end

    if destination == "index.html"
        local content = replace(content, "{RECENT_BLOG_POSTS}" => join(posts_list[1:5]))
    end

    local output =
        replace(header, "{TITLE}" => title, "{DESCRIPTION}" => description) *
        content *
        footer
    open("build/$destination", "w") do io
        write(io, output)
    end
end

# Wrap it up
@suppress begin
    run(`cp -a src/public/. build/`)
    run(`./tailwindcss -i src/input.css -o build/main.css --minify`)
    run(
        `html-minifier --input-dir ./build --output-dir ./build --collapse-whitespace --minify-js true --file-ext html`,
    )
end

println("\rWebsite has been generated!")
