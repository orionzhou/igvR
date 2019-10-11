# IGV
An R package providing interactive connections to
[igv.js](https://github.com/igvteam/igv.js/tree/master) 
(the Integrative Genomics Viewer) running in a web browser

Based upon the Bioconductor R package
[BrowserViz](https://paul-shannon.github.io/BrowserViz/) - of which it
is a subclass - **igvR** offers easy interactive visual exploration of
genomic data from R:

  -   Bed (annotation) and BedGraph (quantitative)
tracks can be created out of **_R_** data.frames and GenomicRanges
objects.  
   - Aligment data from bam files via GAlignments objects offered by
     the GenomicAlignments class
   - variant data from VCF files via VCF objects offered by the
     VariantAnnotation class.
   
   
Here, for example, we display a BAM pileup from a ChIP-Seq experiment, accompanied by narrow
peaks called by MACS2, and TF motif matches from MotifDb to sequence
scored by the Bioconductor's Biostrings::matchPWM, and showing a
browser popup with the motif logo associated with the transcription
factor CTCF, obtained by clicking on a region displayed in the lowest
track.

Code for this example is in the vignette titled 

```
Explore ChIP-seq alignments from a bam file, MACS2 narrowPeaks, and motif matching, near GATA2
```


![alt tag](https://raw.githubusercontent.com/paul-shannon/igvR/master/docs/ctcf-chip-seq-igvR.png)




