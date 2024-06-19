module FileFormatHelper

export @iodef, Reserved, Skip

#-----------------------------------------------------------------------------# Field
# Parse a "field annotation" into parts the @iodef macro needs.  Accepts one of:
    # name::Type = [read_expr, write_expr]
    # name::Type = read_expr
    # name::Type
struct Field
    fieldname::Symbol
    fieldtype::Union{Symbol, Expr}  # MyType, MyType{T}, etc.
    read_expr::Expr
    write_expr::Union{Symbol, Expr}  # Base.write(obj, $write_expr)
end
function Base.show(io::IO, ::MIME"text/plain", part::Field)
    c = get(io, :color, false)
    print(io, "Field(")
    print(io, part.fieldname)
    printstyled(io, "::", part.fieldtype, color = c ? :light_black : normal)
    print(io, ')')
    printstyled(io, " ", part.read_expr, color = c ? :light_cyan : normal)
    printstyled(io, " ", part.write_expr, color = c ? :light_green : normal)
end

function Field(e::Expr)
    # name::Type = [read_expr, write_expr]
    if e.head == :(=) && e.args[1].head == :(::) && e.args[2].head in [:vect, :hcat]
        name, type = e.args[1].args
        read_expr, write_expr = e.args[2].args
        Field(name, type, read_expr, write_expr)

    # name::Type = read_expr
    elseif e.head == :(=) && e.args[1].head == :(::)
        name, type = e.args[1].args
        read_expr = e.args[2]
        Field(:($name::$type = [$read_expr, $name]))

    elseif e.head == :(::)
        name, type = e.args
        Field(:($name::$type = [Base.read(io, $type), $name]))
    else
        error("Unhandled Expr: $e")
    end
end


name(f::Field) = f.fieldname
type(f::Field) = f.fieldtype
type_annotation(f::Field) = :($(f.fieldname)::$(f.fieldtype))
read_expr(f::Field) = :($(f.fieldname) = $(f.read_expr))
write_expr(f::Field) = :(n += Base.write(io, $(f.write_expr)))


#-----------------------------------------------------------------------------# @iodef
macro iodef(e)
    Base.remove_linenums!(e)
    e.head == :struct || error("@iodef must be used on a struct epression.  Found $(e.head).")
    T = e.args[2] isa Symbol ? e.args[2] : e.args[2].args[1]

    fields = Field.(e.args[end].args)

    e.args[end] = Expr(:block, type_annotation.(fields)...)

    esc(quote
        $e

        function Base.read(io::IO, ::Type{$T})
            $(read_expr.(fields)...)
            return $T($(name.(fields)...))
        end
        Base.read(file::AbstractString, ::Type{$T}) = open(io -> Base.read(io, $T), file)

        function Base.write(io::IO, o::$T)
            (; $(name.(fields)...)) = o
            n = 0
            $(write_expr.(fields)...)
            return n
        end
        Base.write(file::AbstractString, ::Type{$T}) = open(io -> Base.write(io, $T), file, "w")
    end)
end

#-----------------------------------------------------------------------------# roundtrip
function roundtrip(x::T) where {T}
    io = IOBuffer()
    write(io, x)
    seekstart(io)
    return read(io, T)
end

#-----------------------------------------------------------------------------# Reserved
struct Reserved{N}
    data::NTuple{N, UInt8}
end
Reserved{N}() where {N} = Reserved{N}(ntuple(_ -> 0, Val(N)))
Base.read(io::IO, ::Type{Reserved{N}}) where {N} = Reserved{N}(ntuple(_ -> read(io, UInt8), Val(N)))
Base.write(io::IO, r::Reserved{N}) where {N} = sum(write(io, x) for x in r.data)

#-----------------------------------------------------------------------------# Skip
struct Skip{N} end
Base.read(io::IO, ::Type{Skip{N}}) where {N} = (skip(io, N); Skip{N}())
Base.write(io::IO, s::Skip{N}) where {N} = write(io, zeros(UInt8, N))

end
