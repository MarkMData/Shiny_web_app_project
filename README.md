
# Building a Shiny Web App in R  
*Note: To run the app on a local machine the app.R, project_functions.R, and report.RMD files as well as the folder containing the RData files must be copied into working directory*  

### Overview

This was a project I completed as part of an R programming module from an MSc in Data Analytics  

This aim of this project was to build a Shiny app which visualises and summarises metorological data collected at 20 locations across the United Kingdom and also calculates and displays a diagnostic called the Hutton Criteria which is used to alert farmers of the risk of potato blight forming on potato crops.  
  
The app was required to have the following functionality:
- Allow the user to select up to five locations which should then be displayed on a map
- Allow the user to select one of four weather variables
- Allow the user to select the aggregation level of the weather variable data to be displayed
- Allow the user to select the time period to display
- Produce a variety of time series plots for the summary statistics of weather variable for selected sites
- Display a table of the daily means for all weather variables for selected sites
- Produce a downloadable report of plots, table, and map for selected sites and weather variable
- Produce a downloadable csv file of the table
- Calculate and display the Hutton Criteria for a user selected location and month
### Approach  
With quite a lot of infomation needing to be displayed I decided to go with a two page layout using the flatly theme. The first page is used for displaying the meteorological data and has a sidebar containing the user selectable options on the left, and a tabset panel on the right with a tab each for the location map, plot, table, and downloads.  

![Image of Shiny web app page 1](https://github.com/MarkMData/images/blob/main/Shiny_app_pg1.PNG?raw=true)  

The the second page is used for displaying the Hutton Criteria, and has a fixed panel with infomation about the Hutton criteria on the right and on the left another fixed panel with the user selctable inputs of loaction and month as well as a calender which displays the days when the Hutton criteria has been met. In the background I used a map to display the selected location.  

![Image of Shiny web app page 2](https://github.com/MarkMData/images/blob/main/Shiny_app_pg2.PNG?raw=true)  
To create the app I used a single app.R file for the UI and server code, and a seperate R file for all the functions used for generating the plots, maps, and table. I also created a Rmarkdown file for the downloadable report.  

The data sets for each location were provided to us as csv files and loading these into the app was slow so I converted them all to RData files. I created functions for generating the plots and table which would take as inputs the user selected options and load the Rdata files for the selected sites then clean & wrangle the data (dealing with missing values, duplicates, correcting formatting, and performing aggregations if required) before generating the desired output.
I used the Leaflet package to create the base maps with markers for the selected locations. To show the days the Hutton criteria was met I created a function that takes as input the selected location and month and then loads, cleans & wrangles the data before generating a calender displaying the days the criteria was met.
