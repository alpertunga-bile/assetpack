# Assetpack

Compressing, processing mesh, texture, etc values into single binary file.

## The Idea

- Implement the binary file structure like this:

<pre>
     _____________________________________________________________________________
    | 8 bytes of length of the header info | N length header info | Stored values |
     -----------------------------------------------------------------------------
    0                                      8                      N               M
</pre>

- It is similar to huggingface/safetensors binary structure

## TODO

- [ ] Implement JSON functions
- [ ] Implement insert and extract from binary file with float, struct, etc
