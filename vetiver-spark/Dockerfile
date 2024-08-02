FROM rstudio/r-session-complete:jammy
RUN /opt/R/4.4.0/bin/R -e 'install.packages("pak", repos="https://packagemanager.rstudio.com/cran/__linux__/jammy/latest")' 
RUN /opt/R/4.4.0/bin/R -e 'pak::pak("ggplot2")'

# docker run -it c053a1752613 /bin/bash
# docker build . -f Dockerfile -t databricks
