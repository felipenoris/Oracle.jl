
for (depfun, newfun) in Dict(
    :num_columns => :ncol,
    :num_rows => :nrow,
    :bind_value! => :bind!,
    :bind_variable! => :bind!,
    :execute! => :execute,
    :close! => :close,
    :commit! => :commit,
    :rollback! => :rollback,
    :fetch! => :fetch,
    :fetch_row! => :fetchrow,
    :fetch_rows! => :fetchrows

)
    @eval begin
        ($depfun)(args...) = error($depfun, " was renamed to ", $newfun, ". Check release notes at https://github.com/felipenoris/Oracle.jl/releases.")
    end
end
