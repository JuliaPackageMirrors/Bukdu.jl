# module Bukdu

module Logger

import ..Bukdu: ApplicationController, ApplicationLayout, ApplicationView, LayoutDivision

const level_false =   0
const level_fatal = 100
const level_error = 200
const level_warn  = 300
const level_info  = 400
const level_debug = 500

"""
    Logger.level::Union{Bool,Symbol}

Get the current Logger level.
"""
level = :info::Union{Bool,Symbol}

const levels = Dict{Union{Bool,Symbol},Int}(
    false  => level_false,
    :fatal => level_fatal,
    :error => level_error,
    :warn  => level_warn,
    :info  => level_info,
    :debug => level_debug
)

settings = Dict(
    :level => level_info,
    :have_color => Base.have_color,
    :have_datetime => false,
    :info_prefix => "INFO",
    :info_sub => ""
)

fatal(block::Function) = settings[:level] >= level_fatal && fatal(block())
error(block::Function) = settings[:level] >= level_error && error(block())
warn(block::Function)  = settings[:level] >= level_warn && warn(block())
info(block::Function)  = settings[:level] >= level_info && info(block())
debug(block::Function) = settings[:level] >= level_debug && debug(block())

fatal(args...; kw...) = settings[:level] >= level_fatal && print_log(:magenta, "FATAL", "", args...; kw...)
error(args...; kw...) = settings[:level] >= level_error && print_log(:red, "ERROR", "", args...; kw...)
warn(args...; kw...)  = settings[:level] >= level_warn && print_log(:yellow, "WARN ", "", args...; kw...)
info(args...; kw...)  = settings[:level] >= level_info && print_info(args...; kw...)
debug(args...; kw...) = settings[:level] >= level_debug && print_log(:cyan, "DEBUG", "", args...; kw...)

"""
    Logger.set_level(lvl::Union{Symbol,Bool})

Set the log level.
Options: `:debug`, `:info`, `:error`, `:warn`, `:fatal`, `false`

```julia
julia> Logger.set_level(false)
false
```
"""
function set_level(lvl::Union{Symbol,Bool})
    if haskey(levels, lvl)
        global level
        settings[:level] = levels[lvl]
        level = lvl
    else
        valids = join(map(repr, keys(levels)), ", ")
        throw(ArgumentError("invalid argument for level"))
    end
end

function print_info(args...; kw...)
    prefix = settings[:info_prefix]
    sub = string(settings[:info_sub])
    print_log(:green, prefix, sub, args...; kw...)
end

function inner_callstack(stackframe::Vector{StackFrame})
    !settings[:have_color] && return stackframe
    pat = r"(.* at )(?P<file>.*.jl):(?P<lineno>\d*)"
    string('\n', join(map(stackframe) do frame
        str = string(frame)
        m = match(pat, str)
        isa(m, RegexMatch) ? string(m[1], with_color(:bold, m[:file]), ':', with_color(:bold, m[:lineno])) : nothing
    end, '\n'))
end

function inner_contents(args...)
    if 1 == length(args)
        arg = first(args)
        if any(x->isa(arg,x), [Array, Tuple])
            if isa(arg, Vector{StackFrame})
                inner_callstack(arg)
            else
                inner_contents(arg...)
            end
        else
            arg
        end
    else
        join(map(inner_contents, args), ' ')
    end
end

function print_log(color::Symbol, prefix::String, sub::String, args...; LF=true)
    print(string(
        settings[:have_datetime] ? rpad(string(Dates.now()), 24) : "",
        with_color(color, prefix),
        ' ',
        isempty(sub) ? "" : string(sub, ' '),
        inner_contents(args...),
        (LF ? "\n" : "")))
end

function have_datetime(enabled::Bool)
    settings[:have_datetime] = enabled
end

function have_color(enabled::Bool)
    settings[:have_color] = enabled
end

function with_color(color::Symbol, text)::String
    if settings[:have_color]
        string(Base.text_colors[color], text, Base.color_normal)
    else
        string(text)
    end
end


## log_message
function log_message(prefix::String)
    settings[:info_prefix] = prefix
end

function log_message{AL<:ApplicationLayout}(D::LayoutDivision{AL})
    settings[:info_sub] = D
end

function log_message{AV<:ApplicationView}(::Type{AV})
    settings[:info_sub] = AV.name.name
end

function log_message(modul::Module)
    settings[:info_sub] = Base.module_name(modul)
end

function log_message{AC<:ApplicationController}(c::AC)
    controller = AC
    action = Base.function_name(c[:action])
    settings[:info_sub] = string(AC, '.', action)
end

end # module Bukdu.Logger
