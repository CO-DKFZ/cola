
# == title
# Consensus partitioning for all combinations of methods
#
# == param
# -data A numeric matrix where subgroups are found by columns.
# -top_value_method Method which are used to extract top n rows. Allowed methods
#        are in `all_top_value_methods` and can be self-added by `register_top_value_methods`.
# -partition_method Method which are used to partition samples. 
#        Allowed methods are in `all_partition_methods` and can be self-added 
#        by `register_partition_methods`.
# -max_k Maximal number of subgroups to try. The function will try ``2:max_k`` subgroups.
# -k Alternatively, you can specify a vector k.
# -top_n Number of rows with top values. The value can be a vector with length > 1. When n > 5000, 
#        the function only randomly sample 5000 rows from top n rows. If ``top_n`` is a vector, paritition
#        will be applied to every values in ``top_n`` and consensus partition is summarized from all partitions.
# -mc.cores Number of cores to use. This argument will be removed in future versions.
# -cores Number of cores, or a ``cluster`` object returned by `parallel::makeCluster`.
# -anno A data frame with known annotation of columns.
# -anno_col A list of colors (color is defined as a named vector) for the annotations. If ``anno`` is a data frame,
#       ``anno_col`` should be a named list where names correspond to the column names in ``anno``.
# -sample_by Should randomly sample the matrix by rows or by columns?
# -p_sampling Proportion of the top n rows to sample.
# -partition_repeat Number of repeats for the random sampling.
# -scale_rows Whether to scale rows. If it is ``TRUE``, scaling method defined in `register_partition_methods` is used.
# -verbose Whether to print messages.
# -help Whether to print help messages.
#
# == details
# The function performs consensus partitioning by `consensus_partition` for all combinations of top-value methods and partitioning methods.
#
# It also adjsuts the subgroup labels for all methods and for all k to make them as consistent as possible.
#
# == return 
# A `ConsensusPartitionList-class` object. Simply type object in the interactive R session
# to see which functions can be applied on it.
#
# == author
# Zuguang Gu <z.gu@dkfz.de>
#
# == example
# \dontrun{
# set.seed(123)
# m = cbind(rbind(matrix(rnorm(20*20, mean = 1), nr = 20),
#                 matrix(rnorm(20*20, mean = -1), nr = 20)),
#           rbind(matrix(rnorm(20*20, mean = -1), nr = 20),
#                 matrix(rnorm(20*20, mean = 1), nr = 20))
#          ) + matrix(rnorm(40*40), nr = 40)
# rl = run_all_consensus_partition_methods(data = m, top_n = c(20, 30, 40))
# }
run_all_consensus_partition_methods = function(data, 
	top_value_method = all_top_value_methods(), 
	partition_method = all_partition_methods(), 
	max_k = 6, k = NULL,
	top_n = NULL,
	mc.cores = 1, cores = mc.cores, anno = NULL, anno_col = NULL,
	sample_by = "row", p_sampling = 0.8, partition_repeat = 50, 
	scale_rows = NULL, verbose = TRUE, help = cola_opt$help) {

	if(max_k >= 10) {
		if(help) {
			qqcat_wrap("It is not recommended to set `max_k` larger than 10. Users are suggested to use the function `hierarchical_partition()` to obtain more subgroups. Set the argument `help` to FALSE to turn off this message.\n")
		}
	}

	data = as.matrix(data)
	if(ncol(data) > 500) {
		if(help) {
			qqcat_wrap("You have quite a lot of columns in the matrix. For reducing the runtime, you can use the function `consensus_partition_by_down_sampling()` to apply to a subset of column and the predicts the classes of unselected columns from the selected columns. Or you can use the function `hierarchical_partition()` to apply consensu partitioning in a hierarchical way. Set the argument 'help = FALSE' to turn off this message.\n")
		}
	}

	if(any(rowSds(data) == 0)) {
		stop_wrap("Deteched some rows have zero SD, please remove them.")
	}
	
	cl = match.call()

	.env = new.env(parent = emptyenv())
	
	if(is.data.frame(data)) data = as.matrix(data)
	if(is.null(rownames(data))) rownames(data) = seq_len(nrow(data))

	if(verbose) qqcat("* on a @{nrow(data)}x@{ncol(data)} matrix.\n")

	if(verbose) cat("* calculate top-values.\n")
	all_top_value_list = lapply(top_value_method, function(tm) {
		if(verbose) qqcat("  - calculate @{tm} score for @{nrow(data)} rows.\n")
		all_top_value = get_top_value_method(tm)(data)
		all_top_value[is.na(all_top_value)] = -Inf
		return(all_top_value)
	})
	names(all_top_value_list) = top_value_method
	.env$all_top_value_list = all_top_value_list

	.env$data = data
	res_list = ConsensusPartitionList(
		list = list(), 
		top_value_method = top_value_method, 
		partition_method = partition_method, 
		consensus_class = NULL,
		.env = .env
	)

	if(!is.null(anno)) {
		if(is.atomic(anno)) {
			known_nm = deparse(substitute(anno))
			anno = data.frame(anno)
			colnames(anno) = known_nm
			if(!is.null(anno_col)) {
				anno_col = list(anno_col)
				names(anno_col) = known_nm
			}
		}
		if(nrow(anno) != ncol(data)) {
			stop_wrap("nrow of `anno` should be the same as ncol of the matrix.")
		}
	}

	if(is.null(anno_col)) {
		anno_col = lapply(anno, ComplexHeatmap:::default_col)
	} else {
		if(ncol(anno) == 1 && is.atomic(anno_col)) {
			anno_col = list(anno_col)
			names(anno_col) = colnames(anno)
		} else if(is.null(names(anno_col))) {
			if(length(anno_col) == ncol(anno)) {
				names(anno_col) = colnames(anno)
			} else {
				anno_col = lapply(anno, ComplexHeatmap:::default_col)
			}
		}
		for(nm in names(anno)) {
			if(is.null(anno_col[[nm]])) {
				anno_col[[nm]] = ComplexHeatmap:::default_col(anno[[nm]])
			}
		}
	}
	if(is.null(anno)) {
		anno_col = NULL
	}

	comb = expand.grid(top_value_method, partition_method, stringsAsFactors = FALSE)
	# comb = comb[sample(nrow(comb), nrow(comb)), ]
	od = order(rep(sapply(partition_method, function(x) attr(get_partition_method(x), "execution_time")), each = length(top_value_method)), decreasing = TRUE)
	comb = comb[od, , drop = FALSE]
	lt = lapply(seq_len(nrow(comb)), function(i) {
		tm = comb[i, 1]
		pm = comb[i, 2]
		if(verbose) qqcat("------------------------------------------------------------\n")
		if(verbose) qqcat("* running partition by @{tm}:@{pm}. @{i}/@{nrow(comb)}\n")

		try_and_trace(res <- consensus_partition(top_value_method = tm, partition_method = pm, max_k = max_k, k = k,
				anno = anno, anno_col = anno_col, .env = .env, verbose = verbose,
				top_n = top_n, sample_by = sample_by, p_sampling = p_sampling, partition_repeat = partition_repeat, scale_rows = scale_rows,
				cores = cores), qq("You have an error when doing partition for @{tm}:@{pm}."))
		return(res)
	})
	names(lt) = paste(comb[, 1], comb[, 2], sep = ":")

	for(i in seq_along(lt)) {
		if(!identical(.env, lt[[i]]@.env)) {
			lt[[i]]@.env = .env
		}
	}

	i_error = which(sapply(lt, inherits, "try-error"))
	if(length(i_error)) {
		for(i in i_error) {
			cat(names(lt)[i], ": ", lt[[i]], "\n", sep = "")
		}
		stop_wrap("There are errors when doing mclapply.")
	}

	res_list@list = lt
	data2 = t(scale(t(data)))
	if(verbose) cat("------------------------------------------------------------\n")
	if(verbose) cat("* adjust class labels according to the consensus classifications from all methods.\n")
	reference_class = lapply(lt[[1]]@k, function(k) {
		cl_df = get_consensus_from_multiple_methods(res_list, k)
		# class_ids = cl_df$class
		# mean_dist = tapply(seq_len(ncol(data2)), class_ids, function(ind) {
		# 	n = length(ind)
		# 	if(n == 1) {
		# 		return(Inf)
		# 	}
		# 	sum(dist(t(data2[, ind, drop = FALSE]))^2)/(n*(n-1)/2)
		# })
		# map = structure(names = names(mean_dist)[order(mean_dist)], names(mean_dist))
		# class_ids = as.numeric(map[as.character(class_ids)])
		# cl_df$class = class_ids
		return(cl_df)
	})
	names(reference_class) = as.character(lt[[1]]@k)

	# also adjust between consensus classes
	if(verbose) cat("  - get reference class labels from all methods, all k.\n")
	rc = reference_class[[1]]$class_df$class
	all_k = lt[[1]]@k
	for(i in seq_along(all_k)[-1]) {
		class_df = reference_class[[i]]$class_df
    	class = class_df[, "class"]

    	map = relabel_class(class, rc, full_set = 1:(all_k[i]))
    	l = which( (duplicated(map) | duplicated(map, fromLast = TRUE)) & map != names(map))
    	unmapped = setdiff(names(map), map)
    	if(any(l)) {
    		map[l] = unmapped[1]
    	}
    	map2 = structure(names(map), names = map)
    	
    	reference_class[[i]]$class_df$class = as.numeric(map[as.character(class)])
    	
    	# the class label for the global membership matrix needs to be adjusted
    	reference_class[[i]]$membership = reference_class[[i]]$membership[, as.numeric(map2[as.character(1:all_k[i])]) ]
		colnames(reference_class[[i]]$membership) = paste0("p", 1:all_k[i])
			
		rc = reference_class[[i]]$class_df$class
	}

	res_list@consensus_class = reference_class
	if(verbose) cat("  - adjust class labels for each single method, each single k.\n")
	for(i in seq_along(lt)) {
		res = lt[[i]]
		for(k in res@k) {
			# relabel the class according to the class in the first object
	        ik = which(res@k == k)
	        
        	# following elements need to be relabeled
        	# - res$object_list[[ik]]$classification$class
        	# - column order of res$object_list[[ik]]$membership
        	# - res$object_list[[ik]]$membership_each
        	class_df = get_classes(res, k)
        	class = class_df[, "class"]
        	map = relabel_class(class, reference_class[[ik]]$class_df$class, full_set = 1:k)
        	map2 = structure(names(map), names = map)
      #   	unmapped = setdiff(as.character(1:k), map)
	    	# map = c(map, structure(unmapped, names = unmapped))
	    	# map2 = c(map2, structure(unmapped, names = unmapped))
	    	
        	res@object_list[[ik]]$class_df$class = as.numeric(map[as.character(class)])
        	res@object_list[[ik]]$membership = res@object_list[[ik]]$membership[, as.numeric(map2[as.character(1:k)]) ]
			colnames(res@object_list[[ik]]$membership) = paste0("p", 1:k)
			
			odim = dim(res@object_list[[ik]]$membership_each)
			res@object_list[[ik]]$membership_each = as.numeric(map[as.character(res@object_list[[ik]]$membership_each)])
			dim(res@object_list[[ik]]$membership_each) = odim
	        
	    }
	    lt[[i]] = res
	}
	res_list@list = lt
	res_list@comb = comb
	res_list@call = cl

	if(verbose) qqcat("------------------------------------------------------------\n")

	return(res_list)
}

get_consensus_from_multiple_methods = function(object, k) {

	res = object
	partition_list = NULL
	mean_cophcor = NULL
	pac_score = NULL
	reference_class = NULL
	for(tm in object@top_value_method) {
		for(pm in object@partition_method) {
			nm = paste0(tm, ":", pm)
			obj = object@list[[nm]]
			ik = which(obj@k == k)

			membership = get_membership(obj, k)
			if(is.null(reference_class)) {
	        	reference_class = get_classes(obj, k)[, "class"]
	        } else {
	        	map = relabel_class(get_classes(obj, k)[, "class"], reference_class, full_set = 1:k)
	        	map2 = structure(names(map), names = map)
	        	membership = membership[, as.numeric(map2[as.character(1:k)]) ]
				colnames(membership) = paste0("p", 1:k)
			}

			partition_list = c(partition_list, list(as.cl_partition(membership)))
			pac_score = c(pac_score, get_stats(obj, k)[, "1-PAC"])
		}
	}

	consensus = cl_consensus(cl_ensemble(list = partition_list), weights = pac_score)
	m = cl_membership(consensus)
	class(m) = "matrix"
	colnames(m) = paste0("p", 1:k)
	attr(m, "n_of_classes") = NULL
	attr(m, "is_cl_hard_partition") = NULL
	class = as.vector(cl_class_ids(consensus))
	df = data.frame(class = class)
	df$entropy = apply(m, 1, entropy)

	membership_each = do.call("cbind", lapply(partition_list, function(x) {
		as.vector(cl_class_ids(x))
	}))

	consensus_mat = matrix(1, nrow = nrow(m), ncol = nrow(m))
	for(i in seq_len(nrow(membership_each)-1)) {
		for(j in (i+1):nrow(membership_each)) {
			consensus_mat[i, j] = sum(membership_each[i, ] == membership_each[j, ])/ncol(membership_each)
			consensus_mat[j, i] = consensus_mat[i, j]
		}
 	}
 
	df$silhouette = silhouette(class, dist(t(consensus_mat)))[, "sil_width"]

	return(list(class_df = df, membership = as.matrix(m)))
}


# == title
# Print the ConsensusPartitionList object
#
# == param
# -object A `ConsensusPartitionList-class` object.
#
# == value
# No value is returned.
#
# == author
# Zuguang Gu <z.gu@dkfz.de>
#
setMethod(f = "show",
	signature = "ConsensusPartitionList",
	definition = function(object) {
	
	# obj_name = deparse(substitute(object, env = env))
	obj_name = "object"

	error = try(object@list[[1]]@sample_by, silent = TRUE)
	if(inherits(error, "try-error")) {
		object@list[[1]]@sample_by = "row"
	}

	qqcat("A 'ConsensusPartitionList' object with @{length(object@top_value_method)*length(object@partition_method)} methods.\n")
	qqcat("  On a matrix with @{nrow(object@.env$data)} rows and @{ncol(object@.env$data)} columns.\n")
	qqcat("  Top rows are extracted by '@{paste(object@top_value_method, collapse = ', ')}' methods.\n")
	qqcat("  Subgroups are detected by '@{paste(object@partition_method, collapse = ', ')}' method.\n")
	qqcat("  Number of partitions are tried for k = @{paste(object@list[[1]]@k, collapse = ', ')}.\n")
	qqcat("  Performed in total @{object@list[[1]]@n_partition*length(object@top_value_method)*length(object@partition_method)} partitions by @{object@list[[1]]@sample_by} resampling.\n")
	qqcat("\n")
	qqcat("Following methods can be applied to this 'ConsensusPartitionList' object:\n")
	txt = showMethods(classes = "ConsensusPartitionList", where = topenv(), printTo = FALSE)
	txt = grep("Function", txt, value = TRUE)
	fname = gsub("Function: (.*?) \\(package.*$", "\\1", txt)
	print(fname)
	cat("\n")

	qqcat("You can get result for a single method by, e.g. @{obj_name}[\"@{object@top_value_method[1]}\", \"@{object@partition_method[1]}\"] or @{obj_name}[\"@{object@top_value_method[1]}:@{object@partition_method[1]}\"]\n")
	if(length(object@top_value_method) == 1) {
		ri = qq("\"@{object@top_value_method[1]}\"")
	} else {
		ri = qq("c(\"@{object@top_value_method[1]}\", \"@{object@top_value_method[2]}\")")
	}
	if(length(object@partition_method) == 1) {
		ci = qq("\"@{object@partition_method[1]}\"")
	} else {
		ci = qq("c(\"@{object@partition_method[1]}\", \"@{object@partition_method[2]}\")")
	}
	if(length(object@top_value_method) > 1 | length(object@partition_method) > 1) {
		qqcat("or a subset of methods by @{obj_name}[@{ri}], @{ci}]\n")
	}
})


# == title
# Subset a ConsensusPartitionList object
#
# == param
# -x A `ConsensusPartitionList-class` object.
# -i Index for top-value methods, character or nummeric.
# -j Index for partitioning methods, character or nummeric.
# -drop Whether drop class
#
# == details
# For a specific combination of top-value method and partitioning method, you can also
# subset by e.g. ``x['SD:hclust']``.
#
# == value
# A `ConsensusPartitionList-class` object or a `ConsensusPartition-class` object.
#
# == author
# Zuguang Gu <z.gu@dkfz.de>
#
# == example
# data(golub_cola)
# golub_cola[c("SD", "MAD"), c("hclust", "kmeans")]
# golub_cola["SD", "kmeans"] # a ConsensusPartition object
# golub_cola["SD:kmeans"] # a ConsensusPartition object
# golub_cola[["SD:kmeans"]] # a ConsensusPartition object
# golub_cola["SD", "kmeans", drop = FALSE] # still a ConsensusPartitionList object
# golub_cola["SD:kmeans", drop = FALSE] # still a ConsensusPartitionList object
# golub_cola["SD", ]
# golub_cola[, "hclust"]
# golub_cola[1:2, 1:2]
"[.ConsensusPartitionList" = function (x, i, j, drop = TRUE) {

	cl = as.list(match.call())
	called_args = names(cl)[-1]

	all_top_value_methods = x@top_value_method
	all_partition_methods = x@partition_method
	n_top_value_methods = length(all_top_value_methods)
	n_partition_methods = length(all_partition_methods)

	if(nargs() == 1) {
		return(x)
	}
    if("i" %in% called_args & "j" %in% called_args) {
        if(is.numeric(i)) {
        	i = all_top_value_methods[i]
        }
        if(is.numeric(j)) {
        	j = all_partition_methods[j]
        }
        i = intersect(i, all_top_value_methods)
        j = intersect(j, all_partition_methods)
        if(length(i) == 0) stop_wrap(qq("Some top-value methods were not applied."))
        if(length(j) == 0) stop_wrap(qq("Some partitioning methods were not applied."))

        l = x@comb[, 1] %in% i & x@comb[, 2] %in% j
        l[is.na(l)] = FALSE
        x@comb = x@comb[l, , drop = FALSE]
        x@list = x@list[l]
        x@top_value_method = i
        x@partition_method = j
        if(length(x@list) == 0) {
        	return(NULL)
        }
        if(length(x@list) == 1 && drop) {
        	x = x@list[[1]]
        }
        return(x)
    }
    if(!"i" %in% called_args & "j" %in% called_args) {
        if(is.numeric(j)) {
        	j = all_partition_methods[j]
        }
        j = intersect(j, all_partition_methods)
        if(length(j) == 0) stop_wrap(qq("Some partitioning methods were not applied."))

        l = x@comb[, 2] %in% j
        l[is.na(l)] = FALSE
        x@comb = x@comb[l, , drop = FALSE]
        x@list = x@list[l]
        x@top_value_method = all_top_value_methods
        x@partition_method = j
        if(length(x@list) == 0) {
        	return(NULL)
        }
        if(length(x@list) == 1 && drop) {
        	x = x@list[[1]]
        } 
        return(x)
    }
    if("i" %in% called_args & !"j" %in% called_args) {
    	if(nargs() == 3 & "drop" %in% called_args) {
    		if(length(i) > 1) {
    			stop_wrap("index can only be length 1.")
    		}
    		if(is.numeric(i)) {
	    		i = names(x)[i]
	    	}
	    	a = strsplit(i, ":+")[[1]]
	    	return(x[a[1], a[2], cl$drop])
    	}
    	if(nargs() == 2) {
    		if(length(i) > 1) {
    			stop_wrap("index can only be length 1.")
    		}
	    	if(is.numeric(i)) {
	    		i = names(x)[i]
	    	}
	    	a = strsplit(i, ":+")[[1]]
	    	return(x[a[1], a[2]])
	    }

        if(is.numeric(i)) {
        	i = all_top_value_methods[j]
        }
        i = intersect(i, all_top_value_methods)
        if(length(i) == 0) stop_wrap(qq("Some top-value methods were not applied."))
        
        l = x@comb[, 1] %in% i
        l[is.na(l)] = FALSE
        x@comb = x@comb[l, , drop = FALSE]
        x@list = x@list[l]
        x@top_value_method = i
        x@partition_method = all_partition_methods
        if(length(x@list) == 0) {
        	return(NULL)
        }
        if(length(x@list) == 1 && drop) {
        	x = x@list[[1]]
        }
        return(x)
    }
    
    return(x)
}


# == title
# Subset a ConsensusPartitionList object
#
# == param
# -x A `ConsensusPartitionList-class` object.
# -i Character index for combination of top-value methods and partitioning method in a form of e.g. ``SD:kmeans``.
#
# == value
# A `ConsensusPartition-class` object.
#
# == author
# Zuguang Gu <z.gu@dkfz.de>
#
# == example
# data(golub_cola)
# golub_cola[["SD:kmeans"]]
"[[.ConsensusPartitionList" = function(x, i) {
	if(length(i) != 1) {
		stop_wrap("Length of index can only be one.")
	}
	if(!is.character(i)) {
		stop_wrap("Index can only be character.")
	}
	x[i]
}
