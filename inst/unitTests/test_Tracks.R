library(RUnit)
library(igvR)
library(VariantAnnotation)
#------------------------------------------------------------------------------------------------------------------------
Sys.setlocale("LC_ALL", "C")   # for consistent sort order
#------------------------------------------------------------------------------------------------------------------------
runTests <- function()
{
   test_Track_baseClass_constructor()
   test_VariantTrack_constructor()
   test_AnnotationTrack_constructors()
   test_QuantitativeTrack_constructors()
   test_AlignmentTrack_constructors()

} # runTests
#------------------------------------------------------------------------------------------------------------------------
test_Track_baseClass_constructor <- function()
{
   printf("--- test_Track abstract base class _constructor")

   track <- igvR:::Track(trackType="annotation",
                        sourceType="file",
                        fileFormat="bed",
                        trackName="testOnly",
                        onScreenOrder=1,
                        color="red",
                        height=50,
                        autoTrackHeight=FALSE,
                        minTrackHeight=50,
                        maxTrackHeight=500,
                        visibilityWindow=1000000)

   checkTrue(is(track) == "Track")

} # test_Track_baseClass_constructor
#------------------------------------------------------------------------------------------------------------------------
# two kinds of VariantTrack:
#   1) constructed with an in-memory (local) VCF object
#   2) constructed with a remote url and indexURL
# test both of them here
test_VariantTrack_constructor <- function()
{
   printf("--- test_VariantTrack_constructor")
   f <- system.file("extdata", "chr22.vcf.gz", package="VariantAnnotation")

      # read in a small VCF object shipped with the VariantAnnotation package

   roi <- GRanges(seqnames="22", ranges=IRanges(start=c(50301422, 50989541),
                                                end=c(50312106, 51001328),
                                                names=c("gene_79087", "gene_644186")))
   vcf.sub <- readVcf(f, "hg19", param=roi)
   track <- VariantTrack("chr22-tiny", vcf.sub)
   checkEquals(length(track@vcf.url), 0)
   checkEquals(track@vcf.obj, vcf.sub)

      #----------------------------
      # now try a url track
      #----------------------------

   data.url <- sprintf("%s/%s", "https://s3.amazonaws.com/1000genomes/release/20130502",
                                 "ALL.wgs.phase3_shapeit2_mvncall_integrated_v5b.20130502.sites.vcf.gz")
   index.url <- sprintf("%s.tbi", data.url)
   url <- list(data=data.url, index=index.url)

   track <- VariantTrack("1kg", url)
   checkEquals(length(track@vcf.url), 2)
   checkTrue(is.null(track@vcf.obj))

} # test_VariantTrack_constructor
#------------------------------------------------------------------------------------------------------------------------
# an annotation, roughly speaking, just a table of locations with one or more (perhaps many more) attributes.
# they are provided as files in one of four formats, all nicely supported by michael lawrence's rtracklayer
# package.  test them out here, along with a simple data.frame and a generic GRanges object
test_AnnotationTrack_constructors <- function()
{
   printf("--- test_AnnotationTrack_constructors")

     #----------------------------------------------------------------------------------------
     # read a short 12-column (that is, maximally complete) bed format file from rtracklayer
     #----------------------------------------------------------------------------------------

   bed.filepath <- system.file(package = "rtracklayer", "tests", "test.bed")
   checkTrue(file.exists(bed.filepath))
   tbl.bed <- read.table(bed.filepath, sep="\t", as.is=TRUE, skip=2)
   colnames(tbl.bed) <- c("chrom", "chromStart", "chromEnd", "name", "score", "strand",
                          "thickStart", "thickEnd", "itemRgb", "blockCount", "blockSizes", "blockStarts")

   track.0 <- DataFrameAnnotationTrack("bed file", tbl.bed)
   checkTrue(all(c("DataFrameAnnotationTrack", "igvAnnotationTrack", "Track") %in% is(track.0)))
   checkEquals(trackSize(track.0), 5)
   checkEquals(trackInfo(track.0), list(trackType="annotation",
                                      fileFormat="bed",
                                      source="file",
                                      class="DataFrameAnnotationTrack"))

     #-------------------------------------------------------------------
     # a UCSC BED format object, that is, a GRanges subtype "UCSCData"
     #-------------------------------------------------------------------

   gr.bed <- import(bed.filepath)
   checkTrue("UCSCData" %in% is(gr.bed))   # UCSC BED format
   track.1 <- UCSCBedAnnotationTrack("UCSC bed", gr.bed,  color="blue", displayMode="SQUISHED")
   checkTrue(all(c("UCSCBedAnnotationTrack", "igvAnnotationTrack", "Track") %in% is(track.1)))
   checkEquals(trackSize(track.1), 5)
   checkEquals(trackInfo(track.1), list(trackType="annotation",
                                      fileFormat="bed",
                                      source="file",
                                      class="UCSCBedAnnotationTrack"))

     #--------------------------------------------------------------------------------
     # now a generic GRanges, not necessarily UCSCData, just needs chrom, start, end
     #-------------------------------------------------------------------------------

   gr.simple <- GRanges(tbl.bed[, c("chrom", "chromStart", "chromEnd", "name")])
   track.2 <- GRangesAnnotationTrack("generic GRanges", gr.simple)
   checkTrue(all(c("GRangesAnnotationTrack", "igvAnnotationTrack", "Track") %in% is(track.2)))
   checkEquals(trackSize(track.2), 5)
   checkEquals(trackInfo(track.2), list(trackType="annotation",
                                      fileFormat="bed",
                                      source="file",
                                      class="GRangesAnnotationTrack"))

   gr.simpler <- GRanges(tbl.bed[, c("chrom", "chromStart", "chromEnd")])
   track.3 <- GRangesAnnotationTrack("generic GRanges", gr.simpler)
   checkTrue(all(c("GRangesAnnotationTrack", "igvAnnotationTrack", "Track") %in% is(track.3)))
   checkEquals(trackSize(track.3), 5)
   checkEquals(trackInfo(track.3), list(trackType="annotation",
                                      fileFormat="bed",
                                      source="file",
                                      class="GRangesAnnotationTrack"))


} # test_AnnotationTrack_constructors
#------------------------------------------------------------------------------------------------------------------------
test_QuantitativeTrack_constructors <- function()
{
   printf("--- test_QuantitativeTrack_constructors")

     #----------------------------------------------------------------------------------------
     # read a short 4-column bedGraph file from the rtracklayer test set
     #----------------------------------------------------------------------------------------

   bedGraph.filepath <- system.file(package = "rtracklayer", "tests", "test.bedGraph")
   checkTrue(file.exists(bedGraph.filepath))

      # one metadata line at the top, without leading comment character. skip it.
   tbl.bg <- read.table(bedGraph.filepath, sep="\t", as.is=TRUE, skip=1)
   colnames(tbl.bg) <- c("chrom", "chromStart", "chromEnd", "score")

   track.0 <- DataFrameQuantitativeTrack("bedGraph", tbl.bg, autoscale=TRUE)
   checkTrue(all(c("DataFrameQuantitativeTrack", "QuantitativeTrack", "Track") %in% is(track.0)))
   checkEquals(trackInfo(track.0), list(trackType="quantitative",
                                      fileFormat="bedGraph",
                                      source="file",
                                      class="DataFrameQuantitativeTrack"))
    checkEquals(trackSize(track.0), 9)

     #-------------------------------------------------------------------
     # a UCSC BED format object, that is, a GRanges subtype "UCSCData"
     #-------------------------------------------------------------------

   gr.bed <- import(bedGraph.filepath)
   checkTrue("UCSCData" %in% is(gr.bed))   # UCSC BED format
   track.1 <- UCSCBedGraphQuantitativeTrack("UCSC bg", gr.bed,  color="blue", autoscale=TRUE)
   checkTrue(all(c("UCSCBedGraphQuantitativeTrack", "QuantitativeTrack", "Track") %in% is(track.1)))
   checkEquals(trackSize(track.1), 9)
   checkEquals(trackInfo(track.1), list(trackType="quantitative",
                                      fileFormat="bedGraph",
                                      source="file",
                                      class="UCSCBedGraphQuantitativeTrack"))


     #-------------------------------------------------------------------
     # a simple, hand-built GRanges
     #-------------------------------------------------------------------
    base.loc <- 88883100
    tbl <- data.frame(chrom=rep("chr5", 3),
                      start=c(base.loc, base.loc+100, base.loc + 250),
                      end=c(base.loc + 50, base.loc+120, base.loc+290),
                      name=c("a", "b", "c"),
                      score=runif(3),
                      strand=rep("*", 3),
                      stringsAsFactors=FALSE)

    gr <- GRanges(tbl)
    track <- GRangesQuantitativeTrack("GRangesQTest", gr, autoscale=TRUE)

     #-------------------------------------------------------------------
     # a simple, flawed, hand-built data.frame example: a 3 snp example
     # bedgraph is a 4-column format:
     #    chromA  chromStartA  chromEndA  dataValueA
     # https://genome.ucsc.edu/goldenpath/help/bedgraph.html
     #-------------------------------------------------------------------

   tbl.flawed <- data.frame(chrom=rep("chr7", 3),
                            start=c(base.loc, base.loc+100, base.loc+1000),
                            end=c(base.loc, base.loc+100, base.loc+1000),
                            name=c("rs1", "rs2", "rs3"),    # this is plausible but illegal
                            score=c(0.5, 1.3, 8.9),
                            stringsAsFactors=FALSE)
   checkException(track <- DataFrameQuantitativeTrack("broken", tbl.flawed, autoscale=TRUE), silent=TRUE)
   tbl.fixed <- tbl.flawed[, c(1,2,3,5)]
   track.fixed <- DataFrameQuantitativeTrack("fixed", tbl.fixed, autoscale=TRUE)
   checkTrue(all(c("DataFrameQuantitativeTrack", "QuantitativeTrack", "Track") %in% is(track.fixed)))


} # test_QuantitativeTrack_constructors
#------------------------------------------------------------------------------------------------------------------------
test_AlignmentTrack_constructors <- function()
{
   printf("--- test_AlignementTrack_constructors")
   bamFile <- system.file(package="igvR", "extdata", "psg1.bam")
   stopifnot(file.exists(bamFile))

   which <- GRanges(seqnames = "chr19", ranges = IRanges(42866464, 42879822))
   param <- ScanBamParam(which=which)

   x <- readGAlignments(bamFile, use.names=TRUE, param=param)
   track <- GenomicAlignmentTrack("DNAse", x)
   checkTrue(all(c("GenomicAlignmentTrack", "Track") %in% is(track)))

     # use more of the Track parameters

   track.2 <- GenomicAlignmentTrack("DNAse", x, visibilityWindow=100000)


} # test_AlignementTrack_constructors
#------------------------------------------------------------------------------------------------------------------------
test_BedpeInteractionsTrack <- function()
{
   file.1 <- system.file(package="igvR", "extdata", "sixColumn-demo1-bedpe")
   checkTrue(file.exists(file.1))
   file.2 <- system.file(package="igvR", "extdata", "tenColumn-demo2.bedpe")
   checkTrue(file.exists(file.2))

   tbl.1 <- read.table(file.1, sep="\t", as.is=TRUE)
   checkEquals(dim(tbl.1), c(33, 6))

   track <- BedpeInteractionsTrack("bedpe-6", tbl.1)
   checkTrue(all(c("BedpeInteractionsTrack", "DataFrameAnnotationTrack") %in% is(track)))
   checkEquals(trackInfo(track),
               list(trackType="pairedEndAnnotation",
                    fileFormat="bedpe",
                    source="file",
                    class="BedpeInteractionsTrack"))

   tbl.2 <- read.table(file.2, sep="\t", as.is=TRUE)
   checkEquals(dim(tbl.2), c(2, 10))
   track <- BedpeInteractionsTrack("bedpe-10", tbl.2)

   checkEquals(trackInfo(track),
               list(trackType="pairedEndAnnotation",
                    fileFormat="bedpe",
                    source="file",
                    class="BedpeInteractionsTrack"))

     #--------------------------------------------------------------------------------------
     # todo: follow the VariantTrack strategy, support a url as well as a direct data.frame
     #--------------------------------------------------------------------------------------

   url <- "https://s3.amazonaws.com/igv.org.test/data/gm12878_loops.bedpe.gz"


} # test_BedpeInteractionsTrack
#------------------------------------------------------------------------------------------------------------------------
# demo_kaspar <- function()
# {
#    library(AnnotationHub)
#
#    shoulder <- 50000
#    start.loc <- 88013975 - shoulder
#    end.loc   <- 88199922 + shoulder
#    chrom <- "chr5"
#    mef2c.region <- GRanges(seqnames=chrom, IRanges(start=start.loc, end=end.loc))
#    roi <- sprintf("%s:%d-%d", chrom, start.loc, end.loc)
#    roi <- "chr5:87,909,738-88,281,633"
#    setGenome(igv, "hg19")
#    showGenomicRegion(igv, roi)
#
#    ah <- AnnotationHub()
#    ah.human <- subset(ah, species == "Homo sapiens")
#    histone.tracks <- query(ah.human, c("H3K4me3", "Gm12878", "Peak", "narrow"))  # 3 tracks
#
#    descriptions <- histone.tracks$description
#    titles <- histone.tracks$title
#
#    track.number <- 0
#
#    library (RColorBrewer)
#    colors <-  brewer.pal(length(histone.tracks), "Accent")
#
#    for(name in names(histone.tracks)){
#       track.number <- track.number + 1
#       gr <- histone.tracks[[name]]
#       ov <- findOverlaps(gr, mef2c.region)
#       mef2c.histones <- gr[queryHits(ov)]
#       track.histones <- GRangesQuantitativeTrack(titles[track.number], mef2c.histones[, "pValue"],
#                                                  color=colors[track.number], trackHeight=50)
#       displayTrack(igv, track.histones)
#       } # for track
#
#
#       # dhs regions for this cell line?
#    dnase.tracks <- query(ah.human, c("Gm12878", "dnase", "narrowPeak"))
#    descriptions <- dnase.tracks$description
#    titles <- dnase.tracks$title
#
#    colors <-  brewer.pal(length(dnase.tracks), "Accent")
#    i <- 0
#    for(name in names(dnase.tracks)){
#       i <- i + 1
#       gr <- dnase.tracks[[name]]
#       ov <- findOverlaps(gr, mef2c.region)
#       mef2c.dnase <- gr[queryHits(ov)]
#       #browser()
#       track.dnase <- GRangesQuantitativeTrack(titles[i], mef2c.dnase[, "signalValue"], color=colors[i])
#       displayTrack(igv, track.dnase)
#       } # for track
#
#
#     query(ah, c("dnase", "gm12878"))
#       # AH22506 | wgEncodeAwgDnaseUwdukeGm12878UniPk.narrowPeak.gz
#     gm12878.dhs.gr <- ah[["AH22506"]]
#     mef2c.dhs.ov <- findOverlaps(mef2c.region, gm12878.dhs.gr)  # 62
#     mef2c.dhs <- gm12878.dhs.gr[subjectHits(mef2c.dhs.ov)]
#     #mef2c.dhs.ucscdata <- new("UCSCData", mef2c.dhs)
#     track.mef2c.dhs <- GRangesQuantitativeTrack("DHS", mef2c.dhs[, "signalValue"], color="green", trackHeight=50)
#     displayTrack(igv, track.mef2c.dhs)
#
#
#
#     # GM12878 is a lymphoblastoid cell line produced from the blood of a female donor with northern
#     # and western European ancestry by EBV transformation. It was one of the original HapMap cell
#     # lines and has been selected by the International HapMap Project for deep sequencing using the
#     # Solexa/Illumina platform. This cell line has a relatively normal karyotype and grows
#     # well. Choice of this cell line offers potential synergy with the International HapMap Project
#     # and genetic variation studies. It represents the mesoderm cell lineage. Cells will be obtained
#     # from the Coriell Institute for Medical Research [coriell.org] (Catalog ID GM12878).
#
#    qhs$title
#    qhs$dataprovider
#
#    gr1 <- subset(qhs, title == "wgEncodeUwHistoneGm12878H3k4me3StdPkRep1.narrowPeak.gz")[[1]]
#    gr2 <- subset(qhs, title == "E116-H3K4me3.narrowPeak.gz")[[1]]
#
#    summary(width(gr1))
#
#    qhs <- query(ah, "RefSeq")
#    qhs
#    qhs$genome
#    refseq <- qhs[qhs$genome == "hg19" & qhs$title == "RefSeq Genes"]
#    refseq
#    refseq <- refseq[[1]] ## Downloads
#    refseq
#
#    table(refseq$name)
#    table(table(refseq$name))  # most genes have just one transcript
#
#    promoters <- promoters(refseq)
#    table(width(promoters))
#
#    ov <- findOverlaps(promoters, gr1)
#    ov
#    tbl.ov <- as.data.frame(findOverlaps(promoters, gr1)) # 46022 rows
#
#       # from genecards
#       # chr5:88,717,117-88,904,257(GRCh38/hg38)
#       # chr5:88,013,975-88,199,922(GRCh37/hg19)
#       # Size:187,141
#       # basesOrientation:Minus strand
#
#    shoulder <- 50000
#    start.loc <- 88013975 - shoulder
#    end.loc   <- 88199922 + shoulder
#    chrom <- "chr5"
#    mef2c.region <- GRanges(seqnames=chrom, IRanges(start=start.loc, end=end.loc))
#    roi <- sprintf("%s:%d-%d", chrom, start.loc, end.loc)
#    roi <- "chr5:87,909,738-88,281,633"
#    setGenome(igv, "hg19")
#    showGenomicRegion(igv, roi)
#
#    mef2c.histones.ov <- findOverlaps(mef2c.region, gr1)
#    mef2c.promoter.ov <- findOverlaps(mef2c.region, promoters)
#    mef2c.promoters <- promoters[subjectHits(mef2c.promoter.ov)]
#    mcols(mef2c.promoters) <- mcols(mef2c.promoters)[["name"]]
#    names(mcols(mef2c.promoters)) <- "name"
#    track.mef2c.promoters <- UCSCBedAnnotationTrack("promoter", mef2c.promoters, color="blue")
#    setGenome(igv, "hg19")
#    showGenomicRegion(igv, roi)
#    displayTrack(igv, track.mef2c.promoters)
#    mef2c.histones <- gr1[subjectHits(mef2c.histones.ov)]
#    #mef2c.histones.ucscdata <- new("UCSCData", mef2c.histones)
#    #mcols(mef2c.histones.ucscdata) <- mcols(mef2c.histones.ucscdata)$pValue
#    #names(mcols(mef2c.histones.ucscdata)) <- "score"
#
#    tbl.histones <- as.data.frame(mef2c.histones)[, c("seqnames", "start", "end", "score")]
#
#    #track.histones <- UCSCBedGraphQuantitativeTrack("histone", mef2c.histones[, "pValue"])
#    track.histones <- GRangesQuantitativeTrack("histone", mef2c.histones[, "pValue"])
#    #track.histones <- DataFrameQuantitativeTrack("H3k4me3", tbl.histones, color="red")
#    displayTrack(igv, track.histones)
#
#       # dhs regions for this cell line?
#     query(ah, c("dnase", "gm12878"))
#       # AH22506 | wgEncodeAwgDnaseUwdukeGm12878UniPk.narrowPeak.gz
#     gm12878.dhs.gr <- ah[["AH22506"]]
#     mef2c.dhs.ov <- findOverlaps(mef2c.region, gm12878.dhs.gr)  # 62
#     mef2c.dhs <- gm12878.dhs.gr[subjectHits(mef2c.dhs.ov)]
#     #mef2c.dhs.ucscdata <- new("UCSCData", mef2c.dhs)
#     track.mef2c.dhs <- GRangesQuantitativeTrack("DHS", mef2c.dhs[, "signalValue"], color="green")
#     displayTrack(igv, track.mef2c.dhs)
#
# } # demo_kaspar
#------------------------------------------------------------------------------------------------------------------------
if(!interactive())
   runTests()
