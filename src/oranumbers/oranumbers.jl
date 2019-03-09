
"""
# Module OraNumbers

The main type for this module is `OraNumber`, which mirrors
the internal representation of `NUMBER` values in Oracle Databases.

# References

* https://docs.oracle.com/cd/B10500_01/appdev.920/a96584/oci03typ.htm
* http://www.ixora.com.au/notes/number_representation.htm
* https://docs.oracle.com/en/database/oracle/oracle-database/18/lnoci/oci-NUMBER-functions.html#GUID-B20FC9D4-B984-4668-999B-1E22387596AF
"""
module OraNumbers

@static if VERSION < v"0.7-"
	import ..Nothing
end

export OraNumber

include("types.jl")
include("encoding.jl")
include("io.jl")
include("base.jl")
include("arithmetic.jl")

end # module
