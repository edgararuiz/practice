FROM rstudio/r-session-complete:jammy
RUN /opt/R/4.4.0/bin/R -e 'options(repos = c(CRAN = "https://packagemanager.rstudio.com/cran/__linux__/jammy/latest"))'
RUN /opt/R/4.4.0/bin/R -e 'install.packages("pak", repos="https://packagemanager.rstudio.com/cran/__linux__/jammy/latest")' 
RUN /opt/R/4.4.0/bin/R -e 'pak::pak(c("tidyverse", "sparklyr", "pysparklyr", "chattr", "DBI", "odbc"))'
RUN /opt/R/4.4.0/bin/R -e 'reticulate::install_python(version = "3.10")' 

# docker run -it databricks /bin/bash
# docker build . -f Dockerfile -t databricks
