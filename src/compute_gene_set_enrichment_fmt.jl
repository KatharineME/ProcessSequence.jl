include("make_ins.jl")
include("sum_ins.jl")
include("sum_values.jl")


function compute_gene_set_enrichment(
    gene_values::Array{
        Float64,
        1
    },
    genes::AbstractArray{
        String,
        1
    },
    gene_set_genes::Array{
        String,
        1
    };
    sort_gene_values::Bool = true,
    gene_index::Union{
        Dict{
            String,
            Int64
        },
        Nothing
    } = nothing,
    compute_cumulative_sum::Bool = true,
)
    
    if sort_gene_values

        sort_indices = sortperm(gene_values)

        gene_values = gene_values[sort_indices]

        genes = genes[sort_indices]

    end

    abs_gene_values = abs.(gene_values)

    # TODO: Check the best practice to check for nothing
    if gene_index === nothing
        
        ins = make_ins(
            genes,
            gene_set_genes,
        )
    
    else
        
        ins = make_ins(
            gene_index,
            gene_set_genes,
        )
        
    end

    in_values_sum = sum_values(
        abs_gene_values,
        ins,
    )

    n_gene = length(genes)
    
    d_down = -1 /
             (n_gene -
              sum_ins(ins))
    
    value = 0.0

    if compute_cumulative_sum

        cumulative_sum = Array{
            Float64,
            1
        }(
            undef,
            n_gene,
        )

    else

        # TODO: Check the best practice to check for nothing
        cumulative_sum = nothing

    end
    
    min_ = 0.0
    
    max_ = 0.0

    auc = 0.0
    
    @inbounds @fastmath @simd for index in 1:n_gene
        
        if ins[index] == 1
            
            value += abs_gene_values[index] /
                     in_values_sum
            
        else
            
            value += d_down
            
        end
        
        if compute_cumulative_sum

            cumulative_sum[index] = value

        end
        
        if value < min_
            
            # TODO: Benchmark against min_ = minimum((value, min_))
            min_ = value
            
        elseif max_ < value
            
            # TODO: Benchmark against max_ = maximum((value, max_))
            max_ = value
            
        end

        auc += value
            
    end
    
    cumulative_sum,
    min_,
    max_,
    auc
    
end


function compute_gene_set_enrichment(
    gene_values::Array{
        Float64,
        1
    },
    genes::AbstractArray{
        String,
        1
    },
    gene_set_genes::Array{
        String,
        1
    };
    sort_gene_values::Bool = true,
)

    if sort_gene_values

        sort_indices = sortperm(gene_values)

        gene_values = gene_values[sort_indices]

        genes = genes[sort_indices]

    end

    if length(gene_set_genes) < 10
        
        gene_index = nothing
        
    else
        
        gene_index = Dict(gene => index for (
            gene,
            index
        ) in zip(
            genes,
            1:length(genes),
        ))
        
    end

    gene_set_enrichment = Dict{
        String,
        Tuple{
            Union{
                Array{
                    Float64,
                    1
                },
                Nothing
            },
            Float64,
            Float64,
            Float64
        }
    }()

    for (
        gene_set,
        gene_set_genes_
    ) in gene_set_genes

        gene_set_enrichment[gene_set] = compute_gene_set_enrichment(
            gene_values,
            genes,
            gene_set_genes_;
            sort_gene_values = false,
            gene_index = gene_index,
            compute_cumulative_sum = false,
        )

    end

    gene_set_enrichment
    
end