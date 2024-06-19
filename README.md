# FileFormatHelper

**FileFormatHelper** is a Julia package that helps write structs which represent (part of) a file format.

## Usage

The `@iodef` macro generates `Base.read` and `Base.write` methods for the struct.

```julia
using FileFormatHelper

@iodef struct Header
    magic::UInt32
    version::UInt32
    reserved::Reserved{4}
    nlines::UInt32
end

h = Header(12345678, 1, Reserved{4}(), 100)

path = tempname()

write(path, h)

h2 = read(path, Header)

h == h2
```

### Custom Readers/Writers

If you want to use a field with a type that doesn't have a defined `Base.read`/`Base.write` methods, you can provide your own.  The syntax is:

```
field::Type = [read_expr, write_obj]
```

where

- `read_expr` is an expression that reads the field from an `io::IO` object.
- `write_expr` is an object that will be written via `Base.write(io, write_expr)`.


Note that both `read_expr` and `write_expr` are evaluated in the context of the struct, so you can refer to other fields.  Additionally, the `read_expr` has access to the `io` object.


```julia
@iodef struct MyFile
    header::Header
    messages::Vector{String} = [[readline(io) for _ in 1:header.nlines], join(messages, '\n')]
end

myfile = MyFile(Header(12345678, 1, Reserved{4}(), 3), ["Hello", "World", "!!!"])

path = tempname()

write(path, myfile)

myfile2 = read(path, MyFile)
```
