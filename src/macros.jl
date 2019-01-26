
macro parse_opt_field_param(struct_variable, field_name, field_type)
    return quote
        if $(esc(field_name)) != nothing
            $(esc(struct_variable)).$(field_name) = $(field_type)($(esc(field_name)))
        end
    end
end

macro parse_opt_field_param(struct_variable, field_name)
    return quote
        if $(esc(field_name)) != nothing
            $(esc(struct_variable)).$(field_name) = $(esc(field_name))
        end
    end
end
