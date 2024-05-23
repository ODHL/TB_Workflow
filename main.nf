#!/usr/bin/env nextflow
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    nf-core/tbdetection
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Github : https://github.com/nf-core/tbdetection
    Website: https://nf-co.re/tbdetection
    Slack  : https://nfcore.slack.com/channels/tbdetection
----------------------------------------------------------------------------------------
*/

nextflow.enable.dsl = 2

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS / WORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
// Main workflows
include { TBGenomics              } from './workflows/tbdetection'
include { TestPrep                } from './workflows/testprep'

// Subworkflows
include { CREATE_INPUT_CHANNEL    } from './subworkflows/local/create_input_channel'
include { PIPELINE_INITIALISATION } from './subworkflows/local/utils_nfcore_tbdetection_pipeline'
include { PIPELINE_COMPLETION     } from './subworkflows/local/utils_nfcore_tbdetection_pipeline'
include { getGenomeAttribute      } from './subworkflows/local/utils_nfcore_tbdetection_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    NAMED WORKFLOWS FOR PIPELINE
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// WORKFLOW: PREPARE TEST DATA
workflow OhioTestPrep {
    // set test samplesheet
    samplesheet = file(params.input)
    if(params.isTest==false) {exit 1, "YEP"}
    main:
        // prep input
        CREATE_INPUT_CHANNEL(
            samplesheet
        )

        // Download test data
        TestPrep(CREATE_INPUT_CHANNEL.out.reads)

    emit:
        fastq = TestPrep.out.fastq
}

//
// WORKFLOW: Run main analysis pipeline depending on type of input
//
workflow NFCORE_OhioTBGenomics {
    if (params.input) { ch_input = file(params.input) } else { exit 1, 'For -entry NFCORE_OhioTBGenomics: Input samplesheet not specified!' }

    take:
    samplesheet // channel: samplesheet read in from --input

    main:

    // Initialize
     PIPELINE_INITIALISATION (
        params.version,
        params.help,
        params.validate_params,
        params.monochrome_logs,
        args,
        params.outdir,
        params.input
    )

    //
    // WORKFLOW: Run pipeline
    //
    TBGenomics (
        samplesheet
    )

    PIPELINE_COMPLETION (
        params.email,
        params.email_on_fail,
        params.plaintext_email,
        params.outdir,
        params.monochrome_logs,
        params.hook_url,
        TBGenomics.out.multiqc_report
    )

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
