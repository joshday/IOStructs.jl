# IOStructs

**IOStructs** is a Julia package that helps write structs which represent (part of) a file format.

## Usage

### `@iodef`

The `@iodef` macro generates `Base.read` and `Base.write` methods for the struct.

```julia
using IOStructs

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

If you want to use a field with a type that doesn't have defined `Base.read`/`Base.write` methods, you can provide your own.  The syntax is:

```
# Provide a custom reader only
field::Type = read_expr

# Provide custom reader and writer
field::Type = [read_expr, write_expr]
```

where

- `read_expr` is an expression that reads the field from an `io::IO` object.  This expression can use any field names defined before it in the struct.
- `write_expr` is an object that will be written via `Base.write(io, write_expr)`.  This expression can use all of the field names.


Note that both `read_expr` and `write_expr` are evaluated in the context of the struct, so you can refer to other fields.  Additionally, the `read_expr` has access to the `io` object.

#### Example

```julia
@iodef struct MyFile
    h::Header
    messages::Vector{String} = [[readline(io) for _ in 1:h.nlines], join(messages, '\n')]
end

myfile = MyFile(Header(12345678, 1, Reserved{4}(), 3), ["Hello", "World", "!!!"])

path = tempname()

write(path, myfile)

myfile2 = read(path, MyFile)

myfile == myfile2
```

### Testing with `roundtrip`

The `IOStructs.roundtrip` is a simple function that writes a struct to a stream and reads it back in.  It's useful for testing that the `Base.read` and `Base.write` methods are working correctly.

### `Reserved{N}` and `Skip{N}`


Sometimes file formats have reserved or unused sections.  Both `Reserved` and `Skip` are used to represent these sections.  The difference is that:

- For `Reserved{N}`, the underlying data is stored as a `NTuple{N, UInt8}`.
- For `Skip{N}`, the underlying data is not stored at all.  Writing a `Skip{N}` will write `0x00` `N` times.
