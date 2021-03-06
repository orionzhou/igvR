% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/VariantTrack.R
\docType{class}
\name{VariantTrack-class}
\alias{VariantTrack-class}
\alias{VariantTrack}
\title{Constructor for VariantTrack}
\usage{
VariantTrack(
  trackName,
  vcf,
  trackHeight = 50,
  anchorColor = "pink",
  homvarColor = "rgb(17,248,254)",
  hetvarColor = "rgb(34,12,253)",
  homrefColor = "rgb(200,200,200)",
  displayMode = "EXPANDED",
  visibilityWindow = 1e+05
)
}
\arguments{
\item{trackName}{A character string, used as track label by igv, we recommend unique names per track.}

\item{vcf}{A VCF object from the VariantAnnotation package, or a list(url=x, index=y) pointing to a vcf file}

\item{trackHeight}{track height, typically in range 20 (for annotations) and up to 1000 (for large sample vcf files)}

\item{anchorColor}{CSS color name (e.g., "red" or "#FF0000") for the "anchoring" graphical segment in the track}

\item{homvarColor}{CSS color name for homozygous variant samples, rgb(17,248,254) by default (~turquoise)}

\item{hetvarColor}{CSS color name for heterzygous variant samples, rgb(34,12,253) by default (~royalBlue)}

\item{homrefColor}{CSS color names for homozygous reference samples, rgb(200,200,200) by default (~lightGray)}

\item{displayMode}{"COLLAPSED", "EXPANDED", or "SQUISHED"}

\item{visibilityWindow}{Maximum window size in base pairs for which indexed annotations or variants are displayed. Defaults: 1 MB for variants, whole chromosome for other track types.}
}
\value{
A VariantTrack object
}
\description{
\code{VariantTrack} creates an \code{IGV} track for VCF (variant call format) objects, either local or at a remote url
}
\details{
Detailed description goes here
}
\examples{

    #----------------------------
    #  first, from a local file
    #----------------------------

f <- system.file("extdata", "chr22.vcf.gz", package="VariantAnnotation")
roi <- GRanges(seqnames="22", ranges=IRanges(start=c(50301422, 50989541),
                                              end=c(50312106, 51001328),
                                              names=c("gene_79087", "gene_644186")))
vcf.sub <- VariantAnnotation::readVcf(f, "hg19", param=roi)
track.local <- VariantTrack("chr22-tiny", vcf.sub)

    #----------------------------
    # now try a url track
    #----------------------------

data.url <- sprintf("\%s/\%s", "https://s3.amazonaws.com/1000genomes/release/20130502",
                               "ALL.wgs.phase3_shapeit2_mvncall_integrated_v5b.20130502.sites.vcf.gz")
index.url <- sprintf("\%s.tbi", data.url)
url <- list(data=data.url, index=index.url)

track.url <- VariantTrack("1kg", url)

}
