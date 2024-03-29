create_cci_template <- function(
  analysis_inputs
) {
  template <- CJ(
    EMITTER_CELLTYPE = analysis_inputs$cell_types,
    RECEIVER_CELLTYPE = analysis_inputs$cell_types,
    LRI = analysis_inputs$LRI$LRI
  )
  template <- merge.data.table(
    x = template,
    y = analysis_inputs$LRI,
    by.x = "LRI",
    by.y = "LRI",
    all.x = TRUE,
    sort = FALSE
  )
  template <- add_cell_number(
    template_table = template,
    condition_inputs = analysis_inputs$condition,
    metadata = analysis_inputs$metadata
  )
  if(analysis_inputs$condition$is_samp) {
    template <- add_sample_number(
      template_table = template,
      condition_inputs = analysis_inputs$condition,
      metadata = analysis_inputs$metadata
    )
  }
  return(template)
}

add_sample_number <- function(
  template_table,
  condition_inputs,
  metadata
) {
  dt_NSAMPLES <- unique(
    metadata[, c("cell_type", "sample_id", "condition")]
  )[, .N, by = c("cell_type", "condition")]
  dt_NSAMPLES <- dcast.data.table(
    data = dt_NSAMPLES,
    formula = cell_type ~ condition,
    value.var = "N"
  )
  template_table <- merge.data.table(
    x = template_table,
    y = dt_NSAMPLES,
    by.x = "EMITTER_CELLTYPE",
    by.y = "cell_type",
    all.x = TRUE,
    sort = FALSE
  )
  template_table <- merge.data.table(
    x = template_table,
    y = dt_NSAMPLES,
    by.x = "RECEIVER_CELLTYPE",
    by.y = "cell_type",
    all.x = TRUE,
    sort = FALSE,
    suffixes = c("_L", "_R")
  )
  new_cols <- c(
    paste0("EMITTER_NSAMPLES_", condition_inputs$cond1),
    paste0("EMITTER_NSAMPLES_", condition_inputs$cond2),
    paste0("RECEIVER_NSAMPLES_", condition_inputs$cond1),
    paste0("RECEIVER_NSAMPLES_", condition_inputs$cond2)
  )
  setnames(
    x = template_table,
    old = c(
      paste0(condition_inputs$cond1, "_L"),
      paste0(condition_inputs$cond2, "_L"),
      paste0(condition_inputs$cond1, "_R"),
      paste0(condition_inputs$cond2, "_R")
    ),
    new = new_cols
  )
  for (j in new_cols) {
    set(
      template_table,
      i = which(is.na(template_table[[j]])),
      j = j,
      value = 0
    )
  }
  return(template_table)
}

add_cell_number <- function(
  template_table,
  condition_inputs,
  metadata
) {
  if (!condition_inputs$is_cond) {
    dt_NCELLS <- metadata[, .N, by = "cell_type"]
    template_table <- merge.data.table(
      x = template_table,
      y = dt_NCELLS,
      by.x = "EMITTER_CELLTYPE",
      by.y = "cell_type",
      all.x = TRUE,
      sort = FALSE
    )
    template_table <- merge.data.table(
      x = template_table,
      y = dt_NCELLS,
      by.x = "RECEIVER_CELLTYPE",
      by.y = "cell_type",
      all.x = TRUE,
      sort = FALSE,
      suffixes = c("_L", "_R")
    )
    new_cols <- c("NCELLS_EMITTER", "NCELLS_RECEIVER")
    setnames(
      x = template_table,
      old = c("N_L", "N_R"),
      new = new_cols
    )
  } else {
    dt_NCELLS <- metadata[, .N, by = c("cell_type", "condition")]
    dt_NCELLS <- dcast.data.table(
      data = dt_NCELLS,
      formula = cell_type ~ condition,
      value.var = "N"
    )
    template_table <- merge.data.table(
      x = template_table,
      y = dt_NCELLS,
      by.x = "EMITTER_CELLTYPE",
      by.y = "cell_type",
      all.x = TRUE,
      sort = FALSE
    )
    template_table <- merge.data.table(
      x = template_table,
      y = dt_NCELLS,
      by.x = "RECEIVER_CELLTYPE",
      by.y = "cell_type",
      all.x = TRUE,
      sort = FALSE,
      suffixes = c("_L", "_R")
    )
    new_cols <- c(
      paste0("NCELLS_EMITTER_", condition_inputs$cond1),
      paste0("NCELLS_EMITTER_", condition_inputs$cond2),
      paste0("NCELLS_RECEIVER_", condition_inputs$cond1),
      paste0("NCELLS_RECEIVER_", condition_inputs$cond2)
    )
    setnames(
      x = template_table,
      old = c(
        paste0(condition_inputs$cond1, "_L"),
        paste0(condition_inputs$cond2, "_L"),
        paste0(condition_inputs$cond1, "_R"),
        paste0(condition_inputs$cond2, "_R")
      ),
      new = new_cols
    )
  }
  for (j in new_cols) {
    set(
      template_table,
      i = which(is.na(template_table[[j]])),
      j = j,
      value = 0
    )
  }
  return(template_table)
}

run_simple_cci_analysis <- function(
  analysis_inputs,
  cci_template,
  log_scale,
  score_type,
  threshold_min_cells,
  threshold_pct,
  compute_fast
) {
  LOGFC <- LOGFC_ABS <- NULL
  averaged_expr <- aggregate_cells(
    data_tr = analysis_inputs$data_tr,
    metadata = analysis_inputs$metadata,
    is_cond = analysis_inputs$condition$is_cond
  )
  cci_dt <- build_cci_or_drate(
    averaged_expr = averaged_expr,
    cci_template = cci_template,
    max_nL = analysis_inputs$max_nL,
    max_nR = analysis_inputs$max_nR,
    condition_inputs = analysis_inputs$condition,
    threshold_min_cells = threshold_min_cells,
    threshold_pct = threshold_pct,
    cci_or_drate = "cci",
    score_type = score_type
  )
  if (compute_fast) {
    if (!analysis_inputs$condition$is_cond) {
      return(cci_dt[["CCI_SCORE"]])
    } else {
      res_cci <- list(
        cond1 = cci_dt[[paste0(
          "CCI_SCORE_",
          analysis_inputs$condition$cond1
        )
        ]],
        cond2 = cci_dt[[paste0(
          "CCI_SCORE_",
          analysis_inputs$condition$cond2
        )]]
      )
      res_diff_lri <- c(
        lapply(
          1:analysis_inputs$max_nL,
          function(i) {
            cci_dt[[paste0(
              "L", i, "_EXPRESSION_",
              analysis_inputs$condition$cond2
            )]] -
              cci_dt[[paste0(
                "L", i, "_EXPRESSION_",
                analysis_inputs$condition$cond1
              )]]
          }
        ),
        lapply(
          1:analysis_inputs$max_nR,
          function(i) {
            cci_dt[[paste0(
              "R", i, "_EXPRESSION_",
              analysis_inputs$condition$cond2
            )]] -
              cci_dt[[paste0(
                "R", i, "_EXPRESSION_",
                analysis_inputs$condition$cond1
              )]]
          }
        )
      )
      names(res_diff_lri) <- c(
        sapply(
          1:analysis_inputs$max_nL,
          function(i) {
            paste0("L", i, "_DIFF_EXPR")
          }
        ),
        sapply(
          1:analysis_inputs$max_nR,
          function(i) {
            paste0("R", i, "_DIFF_EXPR")
          }
        )
      )
      return(
        c(
          res_cci,
          res_diff_lri
        )
      )
    }
  }
  detection_rate <- aggregate_cells(
    data_tr = 1 * (analysis_inputs$data_tr > 0),
    metadata = analysis_inputs$metadata,
    is_cond = analysis_inputs$condition$is_cond
  )
  drate_dt <- build_cci_or_drate(
    averaged_expr = detection_rate,
    cci_template = cci_template,
    max_nL = analysis_inputs$max_nL,
    max_nR = analysis_inputs$max_nR,
    condition_inputs = analysis_inputs$condition,
    threshold_pct = threshold_pct,
    threshold_min_cells = threshold_min_cells,
    cci_or_drate = "drate",
    score_type = score_type
  )
  dt <- merge.data.table(
    x = cci_dt,
    y = drate_dt,
    by = intersect(names(cci_dt), names(drate_dt)),
    sort = FALSE
  )
  if (analysis_inputs$condition$is_cond) {
    logfc_names <- c(
      sapply(
        1:analysis_inputs$max_nL,
        function(i) {
          paste0("L", i, "_LOGFC")
        }
      ),
      sapply(
        1:analysis_inputs$max_nR,
        function(i) {
          paste0("R", i, "_LOGFC")
        }
      )
    )
    if (log_scale) {
      dt[
        ,
        LOGFC := get(
          paste0(
            "CCI_SCORE_",
            analysis_inputs$condition$cond2
          )
        ) -
          get(
            paste0(
              "CCI_SCORE_",
              analysis_inputs$condition$cond1
            )
          )
      ]
      dt[
        ,
        c(logfc_names) :=
          c(
            lapply(
              1:analysis_inputs$max_nL,
              function(i) {
                get(
                  paste0(
                    "L", i, "_EXPRESSION_",
                    analysis_inputs$condition$cond2
                  )
                ) -
                  get(
                    paste0(
                      "L", i, "_EXPRESSION_",
                      analysis_inputs$condition$cond1
                    )
                  )
              }
            ),
            lapply(
              1:analysis_inputs$max_nR,
              function(i) {
                get(
                  paste0(
                    "R", i, "_EXPRESSION_",
                    analysis_inputs$condition$cond2
                  )
                ) -
                  get(
                    paste0(
                      "R", i, "_EXPRESSION_",
                      analysis_inputs$condition$cond1
                    )
                  )
              }
            )
          )
      ]
    } else {
      dt[
        ,
        LOGFC := log(
          get(
            paste0(
              "CCI_SCORE_",
              analysis_inputs$condition$cond2
            )
          ) /
            get(
              paste0(
                "CCI_SCORE_",
                analysis_inputs$condition$cond1
              )
            )
        )
      ]
      dt[
        ,
        LOGFC := ifelse(
          is.nan(LOGFC),
          0,
          LOGFC
        )
      ]
      dt[
        ,
        c(logfc_names) :=
          c(
            lapply(
              1:analysis_inputs$max_nL,
              function(i) {
                temp <- log(
                  get(
                    paste0(
                      "L", i, "_EXPRESSION_",
                      analysis_inputs$condition$cond2
                    )
                  ) /
                    get(
                      paste0(
                        "L", i, "_EXPRESSION_",
                        analysis_inputs$condition$cond1
                      )
                    )
                )
                ifelse(
                  is.nan(temp),
                  0,
                  temp
                )
              }
            ),
            lapply(
              1:analysis_inputs$max_nR,
              function(i) {
                temp <- log(
                  get(
                    paste0(
                      "R", i, "_EXPRESSION_",
                      analysis_inputs$condition$cond2
                    )
                  ) /
                    get(
                      paste0(
                        "R", i, "_EXPRESSION_",
                        analysis_inputs$condition$cond1
                      )
                    )
                )
                ifelse(
                  is.nan(temp),
                  0,
                  temp
                )
              }
            )
          )
      ]
    }
    dt[, LOGFC_ABS := abs(LOGFC)]
  }
  return(dt)
}

aggregate_cells <- function(
  data_tr,
  metadata,
  is_cond
) {
  if (!is_cond) {
    group <- metadata[["cell_type"]]
  } else {
    group <- paste(
      metadata[["condition"]],
      metadata[["cell_type"]],
      sep = "_"
    )
  }
  sums <- DelayedArray::rowsum(
    x = data_tr,
    group = group,
    reorder = TRUE
  )
  aggr <- sums / as.vector(table(group))
  return(aggr)
}

build_cci_or_drate <- function(
  averaged_expr,
  cci_template,
  max_nL,
  max_nR,
  condition_inputs,
  threshold_min_cells,
  threshold_pct,
  cci_or_drate,
  score_type
) {
  CONDITION_CELLTYPE  <- CELLTYPE <- patterns <- NULL
  full_dt <- copy(cci_template)
  if (cci_or_drate == "cci") {
    name_tag <- "EXPRESSION"
  } else if (cci_or_drate == "drate") {
    name_tag <- "DETECTION_RATE"
  }
  if (!condition_inputs$is_cond) {
    row_id <- "CELLTYPE"
    vars_id <- "CELLTYPE"
    cond1_id <- NULL
    cond2_id <- NULL
    merge_id <- name_tag
    score_id <- "CCI_SCORE"
    dr_id <- "IS_CCI_EXPRESSED"
    n_id <- 1
    pmin_id <- NULL
  } else {
    row_id <- "CONDITION_CELLTYPE"
    vars_id <- c("CELLTYPE", "CONDITION")
    cond1_id <- paste0("_", condition_inputs$cond1)
    cond2_id <- paste0("_", condition_inputs$cond2)
    merge_id <- c(condition_inputs$cond1, condition_inputs$cond2)
    score_id <- paste0(
      "CCI_SCORE_",
      c(condition_inputs$cond1, condition_inputs$cond2)
    )
    dr_id <- paste0(
      "IS_CCI_EXPRESSED_",
      c(condition_inputs$cond1, condition_inputs$cond2)
    )
    n_id <- 2
    pmin_id <- c(cond1_id, cond2_id)
  }
  dt <- as.data.table(
    x = t(averaged_expr),
    keep.rownames = "GENE",
    sorted = FALSE
  )
  if (condition_inputs$is_cond) {
    ct_temp <- strsplit(colnames(dt)[-1], "_")
    lct_temp <- length(ct_temp)
    if(lct_temp %% 2 !=0 ) stop("Internal error in `build_cci_or_drate`")
    ct_temp_keep <- unlist(
      lapply(
        ct_temp,
        function(i) i[[2]]
      )
    )[1:(lct_temp/2)]
    ct_temp_check <- unlist(
      lapply(
        ct_temp,
        function(i) i[[2]]
      )
    )[(lct_temp/2+1):lct_temp]
    if(!identical(ct_temp_check, ct_temp_keep)) {
      stop("Internal error in `build_cci_or_drate`")
    }
    dt <- melt.data.table(
      data = dt,
      id.vars = "GENE",
      measure.vars = patterns(
        paste0("^", condition_inputs$cond1, "_"),
        paste0("^", condition_inputs$cond2, "_")),
      value.factor = FALSE,
      variable.factor = TRUE,
      value.name = c(condition_inputs$cond1, condition_inputs$cond2),
      variable.name = "CELLTYPE"
    )
    dt[, CELLTYPE := ct_temp_keep[CELLTYPE]]
  } else {
    dt <- melt.data.table(
      data = dt,
      id.vars = "GENE",
      value.factor = FALSE,
      variable.factor = FALSE,
      value.name = name_tag ,
      variable.name = "CELLTYPE"
    )
  }
  dt[is.na(dt)] <- 0
  out_names <- c(
    sapply(
      1:max_nL,
      function(i) {
        paste0("L", i, "_", name_tag, pmin_id)
      }
    ),
    sapply(
      1:max_nR,
      function(i) {
        paste0("R", i, "_", name_tag, pmin_id)
      }
    )
  )
  full_dt[
    ,
    c(out_names) :=
      c(
        sapply(
          1:max_nL,
          function(i) {
            as.list(
              dt[.SD,
                 on = c(paste0(
                   "GENE==LIGAND_", i),
                   "CELLTYPE==EMITTER_CELLTYPE"
                 ),
                 mget(paste0("x.", merge_id))
              ]
            )
          }
        ),
        sapply(
          1:max_nR,
          function(i) {
            as.list(
              dt[.SD,
                 on = c(
                   paste0("GENE==RECEPTOR_", i),
                   "CELLTYPE==RECEIVER_CELLTYPE"
                 ),
                 mget(paste0("x.", merge_id))
              ]
            )
          }
        )
      )
  ]
  if (cci_or_drate == "cci") {
    if (score_type == "geometric_mean") {
      full_dt[
        ,
        (score_id) :=
          lapply(
            1:n_id,
            function(x) {
              sqrt(
                do.call(
                  pmin,
                  c(
                    lapply(
                      1:max_nL,
                      function(i) {
                        get(
                          paste0(
                            "L",
                            i,
                            "_",
                            name_tag,
                            pmin_id[x]
                          )
                        )
                      }
                    ),
                    na.rm = TRUE
                  )
                )
                *
                  do.call(
                    pmin,
                    c(
                      lapply(
                        1:max_nR,
                        function(i) {
                          get(
                            paste0(
                              "R",
                              i,
                              "_",
                              name_tag,
                              pmin_id[x]
                            )
                          )
                        }
                      ),
                      na.rm = TRUE
                    )
                  )
              )
            }
          )
      ]
    }
    if (score_type == "arithmetic_mean") {
      full_dt[
        ,
        (score_id) :=
          lapply(
            1:n_id,
            function(x) {
              (
                do.call(
                  pmin,
                  c(
                    lapply(
                      1:max_nL,
                      function(i) {
                        get(
                          paste0(
                            "L",
                            i,
                            "_",
                            name_tag,
                            pmin_id[x]
                          )
                        )
                      }
                    ),
                    na.rm = TRUE
                  )
                )
                +
                  do.call(
                    pmin,
                    c(
                      lapply(
                        1:max_nR,
                        function(i) {
                          get(
                            paste0(
                              "R",
                              i,
                              "_",
                              name_tag,
                              pmin_id[x]
                            )
                          )
                        }
                      ),
                      na.rm = TRUE
                    )
                  )
              ) / 2
            }
          )
      ]
    }
  } else if (cci_or_drate == "drate") {
    full_dt[
      ,
      (dr_id) :=
        lapply(
          1:n_id,
          function(x) {
            is_detected_full(
              x_dr = do.call(
                pmin,
                c(
                  lapply(
                    1:max_nL,
                    function(i) {
                      get(
                        paste0(
                          "L",
                          i,
                          "_",
                          name_tag,
                          pmin_id[x]
                        )
                      )
                    }
                  ),
                  na.rm = TRUE
                )
              ),
              x_ncells = get(
                paste0(
                  "NCELLS_EMITTER",
                  pmin_id[x]
                )
              ),
              y_dr = do.call(
                pmin,
                c(
                  lapply(
                    1:max_nR,
                    function(i) {
                      get(
                        paste0(
                          "R",
                          i,
                          "_",
                          name_tag,
                          pmin_id[x]
                        )
                      )
                    }
                  ),
                  na.rm = TRUE
                )
              ),
              y_ncells = get(
                paste0(
                  "NCELLS_RECEIVER",
                  pmin_id[x]
                )
              ),
              dr_thr = threshold_pct,
              threshold_min_cells = threshold_min_cells
            )
          }
        )
    ]
  }
  return(full_dt)
}

is_detected_full <- Vectorize(
  function(
    x_dr,
    x_ncells,
    y_dr,
    y_ncells,
    dr_thr,
    threshold_min_cells
  ) {
    if (x_dr >= dr_thr &
        x_dr * x_ncells >= threshold_min_cells &
        y_dr >= dr_thr &
        y_dr * y_ncells >= threshold_min_cells
    ) {
      return(TRUE)
    } else {
      return(FALSE)
    }
  }
)

