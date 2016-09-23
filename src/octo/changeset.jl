# module Bukdu.Octo

export default, Changeset, change, cast, validate_length

import Base: ==
import ..ApplicationController

default(T::Type, ::Type{String}) = ""
default(T::Type, ::Type{Int}) = 0

function default(T::Type)::T
    # broadcast #
    # fields = fieldtype.(T,fieldnames(T))
    # T(default.(T, fields)...)
    fields = map(x->fieldtype(T, x), fieldnames(T))
    T(map(x-> default(T, x), fields)...)
end


type Changeset
    model
    changes::Assoc
    function Changeset(model, changes::Assoc)
        T = typeof(model)
        lhs = Assoc(map(x->(x,getfield(model, x)), fieldnames(T)))
        rhs = typed_assoc(T, changes)
        new(model, setdiff(rhs, lhs))
    end
end

function ==(lhs::Changeset, rhs::Changeset)
    T = typeof(lhs.model)
    !isa(rhs.model, T) && return false
    all(x -> ==(getfield(lhs.model, x), getfield(rhs.model, x)), fieldnames(T)) && ==(lhs.changes, rhs.changes)
end

function |>(changeset::Changeset, func::Function)
    func(changeset)
end

function |>(model, func::Function)
    func(change(model))
end

function typed_assoc(T::Type, changes::Assoc)::Assoc
    typ_fieldnames = fieldnames(T)
    Assoc(
        map(filter(kv -> first(kv) in typ_fieldnames, changes)) do kv
        (name,v) = kv
        if name in typ_fieldnames
            fieldT = fieldtype(T, name)
            if isa(v, fieldT)
                (name, v)
            else
                (name, parse(fieldT, v))
            end
        end
    end)
end

function cutout_brackets(typ::Type, param::Tuple{Symbol,Any})::Tuple{Symbol,Any}
    t = lowercase(string(typ))
    (key,value) = param
    k = string(key)
    if startswith(k, "$(t)_")
        key = Symbol(k[length("$(t)_")+1:end])
    elseif startswith(k, "$t[") && endswith(k, "]")
        key = Symbol(last(split(k,"["))[1:end-1])
    end
    (key, value)
end

function change{AC<:ApplicationController}(c::AC, T::Type)::Changeset
    Changeset(default(T), Assoc(map(param->cutout_brackets(T,param), c[:query_params])))
end

function change{T<:Any,AC<:ApplicationController}(c::AC, model::T)::Changeset
    Changeset(model, Assoc(map(param->cutout_brackets(T,param), c[:query_params])))
end

function change(model; kw...)::Changeset
    Changeset(model, Assoc(kw))
end

function change(typ::Type; kw...)::Changeset
    change(default(typ); kw...)
end

function cast(changeset::Changeset, params, required_fields)::Changeset
    changeset
end

function validate_length(changeset::Changeset, field::Symbol; kw...)::Changeset
    changeset
end

function cast(params, required_fields)::Function
    (changeset) -> cast(changeset, params, required_fields)
end

function validate_length(field::Symbol; kw...)::Function
    (changeset) -> validate_length(changeset, field; kw...)
end
