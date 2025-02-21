#' Pathway information annotation of "EC", "KO", "MetaCyc" pathway
#'
#' This function has two primary use cases:
#' 1. Annotating pathway information using the output file from PICRUSt2.
#' 2. Annotating pathway information from the output of `pathway_daa` function, and converting KO abundance to KEGG pathway abundance when `ko_to_kegg` is set to TRUE.
#'
#' @param file A character, address to store PICRUSt2 export files. Provide this parameter when using the function for the first use case.
#' @param pathway A character, consisting of "EC", "KO", "MetaCyc"
#' @param daa_results_df A data frame, output of pathway_daa. Provide this parameter when using the function for the second use case.
#' @param ko_to_kegg A logical, decide if convert KO abundance to KEGG pathway abundance. Default is FALSE. Set to TRUE when using the function for the second use case.
#' @param kegg_limit A numeric, the number of KEGG pathways to be queried at once. It's predefined. Do not change this parameter.
#' @param df_size_limit A numeric, the rows of the data.frame to be queried in total.
#'
#' @return A data frame containing pathway annotation information. The data frame has the following columns:
#' \itemize{
#'   \item \code{feature}: The feature ID of the pathway (e.g., KO, EC, or MetaCyc ID).
#'   \item \code{description}: The description or name of the pathway.
#'   \item Other columns depending on the input parameters and type of pathway.
#' }
#' If \code{ko_to_kegg} is set to TRUE, the output data frame will also include the following columns:
#' \itemize{
#'   \item \code{pathway_name}: The name of the KEGG pathway.
#'   \item \code{pathway_description}: The description of the KEGG pathway.
#'   \item \code{pathway_class}: The class of the KEGG pathway.
#'   \item \code{pathway_map}: The KEGG pathway map ID.
#' }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Prepare the required input files and data frames
#' # Then, you can use the pathway_annotation function as follows:
#'
#' # Use case 1: Annotating pathway information using the output file from PICRUSt2
#' result1 <- pathway_annotation(file = "path/to/picrust2/export/file.txt",
#'                               pathway = "KO",
#'                               daa_results_df = NULL,
#'                               ko_to_kegg = FALSE)
#'
#' # Use case 2: Annotating pathway information from the output of pathway_daa function
#' # and converting KO abundance to KEGG pathway abundance
#' # This use case will be demonstrated using both a hypothetical example, and a real dataset.
#'
#' ## Hypothetical example
#' hypothetical_daa_results_df <- data.frame() # Replace this with your actual data frame
#' result2 <- pathway_annotation(file = NULL,
#'                               pathway = "KO",
#'                               daa_results_df = hypothetical_daa_results_df,
#'                               ko_to_kegg = TRUE)
#'
#' ## Real dataset example
#' # Load the real dataset
#' data(daa_results_df)
#' result3 <- pathway_annotation(file = NULL,
#'                               pathway = "KO",
#'                               daa_results_df = daa_results_df,
#'                               ko_to_kegg = TRUE)
#' }
pathway_annotation <-
  function(file = NULL,
           pathway = NULL,
           daa_results_df = NULL,
           ko_to_kegg = FALSE,
           kegg_limit = 10,
           df_size_limit = 1000) {

    message("Starting pathway annotation...")

    if (is.null(file) && is.null(daa_results_df)) {
      stop("Please input the picrust2 output or results of pathway_daa daa_results_df")
    }
    if (!is.null(file)) {
      message("Reading the input file...")
      file_format <- substr(file, nchar(file) - 3, nchar(file))
      switch(file_format,
             ".txt" = {
               message("Loading .txt file...")
               abundance <- readr::read_delim(
                 file,
                 delim = "\t",
                 escape_double = FALSE,
                 trim_ws = TRUE
               )
               message(".txt file successfully loaded.")
             },
             ".tsv" = {
               message("Loading .tsv file...")
               abundance <- readr::read_delim(
                 file,
                 delim = "\t",
                 escape_double = FALSE,
                 trim_ws = TRUE
               )
               message(".tsv file successfully loaded.")
             },
             ".csv" = {
               message("Loading .csv file...")
               abundance <- readr::read_delim(
                 file,
                 delim = "\t",
                 escape_double = FALSE,
                 trim_ws = TRUE
               )
               message(".csv file successfully loaded.")
             },
             stop(
               "Invalid file format. Please input file in .tsv, .txt or .csv format. The best input file format is the output file from PICRUSt2, specifically 'pred_metagenome_unstrat.tsv'."
             )
      )
      abundance <-
        abundance %>% tibble::add_column(
          description = rep(NA, length = nrow(abundance)),
          .after = 1
        )
      switch(pathway,
             "KO" = {
               message("Loading KO reference data...")
               load(system.file("extdata", "KO_reference.RData", package = "ggpicrust2"))
               message("Annotating abundance data with KO reference...")
               for (i in seq_len(nrow(abundance))) {
                 abundance[i, 2] <- KO_reference[KO_reference[, 1] %in% abundance[i, 1], 5][1]
               }
               message("Abundance data annotation with KO reference completed.")
             },
             "EC" = {
               message("Loading EC reference data...")
               load(system.file("extdata", "EC_reference.RData", package = "ggpicrust2"))
               message("Annotating abundance data with EC reference...")
               for (i in seq_len(nrow(abundance))) {
                 abundance[i, 2] <- EC_reference[EC_reference[, 1] %in% abundance[i, 1], 2]
               }
               message("Abundance data annotation with EC reference completed.")
               message("Note: EC description may appear to be duplicated due to shared EC numbers across different reactions.")
             },
             "MetaCyc" = {
               message("Loading MetaCyc reference data...")
               load(system.file("extdata", "MetaCyc_reference.RData", package = "ggpicrust2"))
               message("Annotating abundance data with MetaCyc reference...")
               for (i in seq_len(nrow(abundance))) {
                 abundance[i, 2] <- MetaCyc_reference[MetaCyc_reference[, 1] %in% abundance[i, 1], 2]
               }
               message("Abundance data annotation with MetaCyc reference completed.")
             },
             stop("Invalid pathway option. Please provide one of the following options: 'KO', 'EC', 'MetaCyc'.")
      )
      return(abundance)
    }
    if (!is.null(daa_results_df)) {
      message("DAA results data frame is not null. Proceeding...")
      if (ko_to_kegg == FALSE) {
        message("KO to KEGG is set to FALSE. Proceeding with standard workflow...")
        daa_results_df$description <- NA
        switch(pathway,
               "KO" = {
                 message("Loading KO reference data...")
                 load(system.file("extdata", "KO_reference.RData", package = "ggpicrust2"))
                 for (i in seq_len(nrow(daa_results_df))) {
                   daa_results_df[i, ]$description <-
                     KO_reference[KO_reference[, 1] %in% daa_results_df[i, ]$feature, 5][1]
                 }
               },
               "EC" = {
                 message("Loading EC reference data...")
                 load(system.file("extdata", "EC_reference.RData", package = "ggpicrust2"))
                 for (i in seq_len(nrow(daa_results_df))) {
                   daa_results_df[i, ]$description <-
                     EC_reference[EC_reference[, 1] %in% daa_results_df[i, ]$feature, 2]
                 }
                 message("EC description may appear to be duplicated")
               },
               "MetaCyc" = {
                 message("Loading MetaCyc reference data...")
                 load(system.file("extdata", "MetaCyc_reference.RData", package = "ggpicrust2"))
                 for (i in seq_len(nrow(daa_results_df))) {
                   daa_results_df[i, ]$description <-
                     MetaCyc_reference[MetaCyc_reference[, 1] %in% daa_results_df[i, ]$feature, 2]
                 }
               },
               stop("Only provide 'KO', 'EC' and 'MetaCyc' pathway")
        )
        message("Returning DAA results data frame...")
        return(daa_results_df)
      } else {
        message("KO to KEGG is set to TRUE. Proceeding with KEGG pathway annotations...")
        daa_results_filtered_df <- daa_results_df[daa_results_df$p_adjust < 0.05, ]
        if (nrow(daa_results_filtered_df) == 0) {
          stop(
            "No statistically significant biomarkers found. 'Statistically significant biomarkers' refer to those biomarkers that demonstrate a significant difference in expression between different groups, as determined by a statistical test (p_adjust < 0.05 in this case).\n",
            "You might consider re-evaluating your experiment design or trying alternative statistical analysis methods. Consult with a biostatistician or a data scientist if you are unsure about the next steps."
          )
        }
        daa_results_filtered_df$pathway_name <- NA
        daa_results_filtered_df$pathway_description <- NA
        daa_results_filtered_df$pathway_class <- NA
        daa_results_filtered_df$pathway_map <- NA
        keggGet_results <- list()
        message(
          "We are connecting to the KEGG database to get the latest results, please wait patiently."
        )

        # KEGG only allows 10 results at once.
        #kegg_limit <- 10

        if (nrow(daa_results_filtered_df) > df_size_limit) {
          cat("\n") # New line
          message(
            "The number of statistically significant pathways exceeds the database's query limit. Truncate only the top entries."
          )

          daa_results_filtered_df <- daa_results_filtered_df[order(daa_results_df$p_adjust)[1:df_size_limit], ]
          cat("\n") # New line

        }

        cat("\n") # New line
        message("Processing pathways in chunks...")
        cat("\n") # New line

        # Initialize a text progress bar
        pb <- txtProgressBar(min = 0, max = nrow(daa_results_filtered_df), style = 3)

        start_time <- Sys.time() # start timer

        # Extract the proper chunk of features to KEGGREST.
        # Modified by Han Hu: 01/24/2024

        # Calculate the number of rounds based on the kegg_limit.
        num_rounds <- ceiling(nrow(daa_results_filtered_df) / kegg_limit)

        # Extract the features within range and query in KEGGREST.
        for(idx in 1:num_rounds) {
          start_idx <- (idx - 1) * kegg_limit + 1
          end_idx <- min(idx * kegg_limit, nrow(daa_results_filtered_df))

          repeat{
            tryCatch(
              {
                # If some IDs are not found in the database, no error thrown:(
                keggGet_results[[idx]] <- KEGGREST::keggGet(daa_results_filtered_df$feature[start_idx:end_idx])
                names(keggGet_results[[idx]]) <- unlist(purrr::map(keggGet_results[[idx]], list("ENTRY", 1)))
                a <- 1
              },
              error = function(e) {
                cat("\n") # New line
                message("An error occurred. Retrying...")
                cat("\n") # New line
              }
            )
            if (a == 1) {
              break
            }
          }

          safe_map <- function(df, property) {
            safe_access <- function (x) {
              if (!is.null(x[[property]]) && length(x[[property]]) >= 1) {
                return(x[[property]][[1]])
              } else {
                return(NA)  # or return("") if you prefer an empty string for missing values
              }
            }
            unlist(purrr::map(df, safe_access))
          }

          matched_idx <- (start_idx:end_idx)[which(daa_results_filtered_df$feature[start_idx:end_idx] %in% names(keggGet_results[[idx]]))]
          # A potential bug: if the length of keggGet_results[[idx]] is different from end_idx - start_idx
          daa_results_filtered_df[matched_idx, ]$pathway_name <- safe_map(keggGet_results[[idx]], "NAME")
          daa_results_filtered_df[matched_idx, ]$pathway_description <- safe_map(keggGet_results[[idx]], "DESCRIPTION")
          daa_results_filtered_df[matched_idx, ]$pathway_class <- safe_map(keggGet_results[[idx]], "CLASS")
          daa_results_filtered_df[matched_idx, ]$pathway_map <- safe_map(keggGet_results[[idx]], "PATHWAY_MAP")

          setTxtProgressBar(pb, end_idx)
        }

        end_time <- Sys.time() # end timer
        time_taken <- end_time - start_time # calculate time taken
        cat("\n") # New line
        message("Finished processing chunks. Time taken: ", round(time_taken, 2), " seconds.")
        cat("\n") # New line

        # Close the progress bar
        close(pb)

        #daa_results_filtered_annotation_df <-
        #  daa_results_filtered_df
        message("Returning DAA results filtered annotation data frame...")
        return(daa_results_filtered_df)
      }
    }
  }
