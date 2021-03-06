
# uPN is the collection of uni-glomerular EM PNs used for analysis in the paper

# convert the neurons into dotprops (point clouds with tangent vectors) for NBLAST
# transform them into a LM template brain (JFRC2)
pndps = dotprops(uPN, k=5, resample=1e3) %>%
  xform_brain(sample=FAFB13, ref=JFRC2)

# clean up glomerular names of PNs
pndps[,'glom'] = gsub("glomerulus ", "", pndps[,'glomerulus'])  

# 180209 removing VCx and VCy since they are ambiguous
pndps = subset(pndps, !(glom %in% c("VCx", "VCy")))

# allbyall for all PNs
pn.aba = nblast_allbyall(pndps, .progress='text')

# hierarchical clustering of the nblast all by all score matrix
pnhc=nhclust(scoremat=pn.aba)

# pdf("170322-PN_glom_nhcluster_FAFB2017.pdf", width=20, height=12)
# plot(pnhc, labels = pndps[,'glom'])
# dev.off()

# retrieve sensilla categories for coloring-----------
# all_sen = catmaid_query_by_annotation("^sensilla_type$",  type="annotation", conn=fafb_conn)$name

# assign colors based on sensilla categories-----------
# the sensilla type info is stored in data/glom_sen_metaData.RData
# use this list to map sensilla types to their corresponding colors
color_pal = c(large_basiconic="blue4", thin_basiconic="skyblue1", 
              small_basiconic="royalblue", T1_trichoid="red", 
              T2_trichoid="orangered2", T3_trichoid="darkorange",
              maxillary_palp_basiconic="springgreen1", antennal_coeloconic="yellow3", 
              antennal_intermediate="purple", unknown="deeppink2")


if (FALSE) {
  # This is how type categories are pulled from CATMAID, 
  # need FAFB CATMAID credential and usually shouldn't need to run this.
  pn_colors = list()
  for (i in all_sen) {
    gloms = catmaid_query_by_annotation(paste0("^", i, "$"),  type="annotation", conn=fafb_conn)$name
    
    skids = lapply(gloms, function(x) paste0("^", x, "$") %>% 
                     catmaid_query_by_annotation(type="neuron", conn=fafb_conn) %>% 
                     .$skid %>%
                     intersect(pn_skids)) %>%
                     {do.call(c, .)}
    
    pn_colors = rep(i, length(skids)) %>%
      setNames(unname(skids)) %>%
      c(pn_colors)
  }
  
  pn_colors = setdiff(names(pndps), names(pn_colors)) %>% 
  {setNames(rep("unknown",length(.)), .)} %>%
    c(pn_colors)
  # correct a DM5 temporarily
  pn_colors['57385'] = pn_colors['27611']
}


#-----
# a better PN color plate

# function------
height_for_ngroups<-function(hc, k) {
  s=sort(hc$height, decreasing=TRUE)
  s[k]-1e-6
}

# plotting the dendrogram----------
hc_plot = pnhc
hc_col = hc_plot$order %>% {hc_plot$labels[.]} %>% {pn_colors[.]} %>% unlist %>% {color_pal[.]}
hc_plot$height=hc_plot$height %>% sqrt
t3 = colour_clusters(hc_plot, k=length(pndps), col=unname(hc_col)) %>%
  color_labels(k=length(pndps), col=unname(hc_col)) %>%
  set("branches_lwd", 4)

labels(t3) = pndps[,'glom'][hc_plot$order]
plot(t3)

# pdf("170327-PN_glom_nhcluster_FAFB2017.pdf", width=20, height=6)

# saving the resultant dendrogram
if (FALSE) {
  pdf("180208-PN_glom_nhcluster_FAFB2017.pdf", width=20, height=6)
  plot(t3, ylab='Height')
  axis(2, lwd = 4)
  dev.off()
}
