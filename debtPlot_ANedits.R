##Updated debtPlot*(version ANedits)

##############
library(pensionviewr)
library(reasontheme)
library(data.table)
library(tidyverse)

reason_color_pal()
library(extrafont)
font_import(pattern="Roboto")
loadfonts(device = "win", quiet = TRUE)
##Palette
#https://www.rapidtables.com/web/color/Web_Safe.html
palette_reason <- data.table(
  Orange = "#FF6633", 
  LightOrange = "#FF9933",
  DarkGrey = "#333333", 
  SpaceGrey = "#A69FA1",
  DarkBlue = "#0066CC",
  GreyBlue = "#6699CC", 
  Yellow = "#FFCC33", 
  LightBlue = "#66B2FF", 
  SatBlue = "#3366CC", 
  Green = "#669900",
  LightGreen = "#00CC66",
  Red = "#CC0000",
  LightRed = "#FF0000")
#https://www.colorbook.io/hexcolors/view/A69FA1

#rgb1 <- col2rgb(palette_reason$Yellow)/255
#rownames(rgb1) <- c("red", "green", "blue")
#rgb1
#Custom color code
#ColorName <- rgb(0.2,0.2,0.4)
#ColorName  

###
##Pull PERSI data
##Load list of plans
pl <- planList()

columns <- c("total_pension_liability_dollar", "wage_inflation",
             "payroll_growth_assumption", "other_contribution_dollar",
             "other_additions_dollar", "x1_year_investment_return_percentage",
             "fiscal_year_of_contribution", "statutory_payment_dollar",
             "statutory_payment_percentage")

#Custom function to load filtered data from the database
filteredData <- function(data, plan, fy){
  Plan <- data.table(pullData(data, plan))
  ##Create missing columns for plans with no data for variables in "columns" vector
  for (i in (1:length(columns))){
    if(sum((colnames(Plan) == columns[i]))==0) {
      Plan[,columns[i] := NA] }
  }
  ####
  Plan <- Plan[year > fy-1]
  Plan <- Plan %>%
    select(
      year,
      plan_name = display_name,
      state,
      return_1yr = x1_year_investment_return_percentage,
      actuarial_cost_method_in_gasb_reporting,
      funded_ratio = actuarial_funded_ratio_percentage,
      actuarial_valuation_report_date,
      ava = actuarial_value_of_assets_gasb_dollar,
      mva = market_value_of_assets_dollar,
      mva_smooth = market_assets_reported_for_asset_smoothing,#added
      aal = actuarially_accrued_liabilities_dollar,
      tpl = total_pension_liability_dollar,
      adec = actuarially_required_contribution_dollar,
      adec_paid_pct = actuarially_required_contribution_paid_percentage,
      statutory = statutory_payment_dollar,#NEW
      statutory_pct = statutory_payment_percentage,#NEW
      amortizaton_method,
      asset_valuation_method_for_gasb_reporting,
      total_benefit_payments = total_benefits_paid_dollar,#added
      benefit_payments = benefit_payments_dollar,
      refunds = refunds_dollar,#added
      admin_exp = administrative_expense_dollar,
      payroll = covered_payroll_dollar,
      ee_contribution = employee_contribution_dollar,
      ee_nc_pct = employee_normal_cost_percentage,
      er_contribution = employer_contribution_regular_dollar,
      er_nc_pct = employer_normal_cost_percentage,
      er_state_contribution = employer_state_contribution_dollar,
      er_proj_adec_pct = employers_projected_actuarial_required_contribution_percentage_of_payroll,
      other_contribution = other_contribution_dollar,#added
      other_additions = other_additions_dollar,#added
      fy_contribution = fiscal_year_of_contribution,
      inflation_assum = inflation_rate_assumption_for_gasb_reporting,
      arr = investment_return_assumption_for_gasb_reporting,
      number_of_years_remaining_on_amortization_schedule,
      payroll_growth_assumption,
      total_amortization_payment_pct = total_amortization_payment_percentage,
      total_contribution = total_contribution_dollar,
      total_nc_pct = total_normal_cost_percentage,
      total_number_of_members,
      total_proj_adec_pct = total_projected_actuarial_required_contribution_percentage_of_payroll,
      type_of_employees_covered,
      uaal = unfunded_actuarially_accrued_liabilities_dollar,
      wage_inflation
    )
}

####Load Idaho PERS data
#View(pl$display_name)
PERSI.debt <- filteredData(pl, "Idaho Public Employee Retirement System", 2001)
PERSI.debt$year <- as.numeric(PERSI.debt$year)
#Set to data.frame for visualization
IPERS <- data.frame(PERSI.debt)
###########
#set reasontheme
set_reason_theme(style = "slide")
tick <- c("axis.ticks = ggplot2::element_blank(),
          axis.ticks.x = ggplot2::element_blank(),
          axis.ticks.y = ggplot2::element_blank()")

####Edit detPlot() manually
############
debtPlot <- function(data, title = NULL, caption = FALSE, grid = FALSE, ticks = TRUE, font) {
  
  data <- data %>%
    dplyr::filter(data$uaal != 0)
  # extrapolate between years linearly
  extrapo <- stats::approx(data$year, data$uaal,  n = 10000)
  extrapo2 <- stats::approx(data$year, data$funded_ratio, n = 10000)
  graph <-
    data.frame(year = extrapo$x,
               uaal = extrapo$y,
               funded_ratio = extrapo2$y) %>%
    tidyr::drop_na()
  graph <- graph %>%
    dplyr::mutate(sign = dplyr::case_when(.data$uaal >= 0 ~ "positive",
                                          .data$uaal < 0 ~ "negative"))
  
  y_minimum <- min(graph$uaal)
  y_maximum <- max(graph$uaal)
  ggplot2::ggplot(graph,
                  ggplot2::aes(x = graph$year)) +
    ggplot2::geom_area(ggplot2::aes(y = graph$uaal, fill = graph$sign)) +#Removed "color" paramater
    ggplot2::geom_line(ggplot2::aes(y = graph$funded_ratio * (y_maximum)),
                       color = palette_reason$GreyBlue,#Referenced Color Palette
                       size = 1.7) +#Increased Size 1.
    #ggtitle(title)+
    # axis labels
    ggplot2::labs(y = "Unfunded Accrued Actuarial Liabilities (Millions)", x = NULL) +
    
    # colors assigned to pos, neg
    ggplot2::scale_fill_manual(
      values = c("negative" = paste(palette_reason$Green),#Referenced Color Palette
                 "positive" = paste(palette_reason$Red)),#Referenced Color Palette
      aesthetics = c("colour", "fill")
    ) +
    # sets the y-axis scale
    ggplot2::scale_y_continuous(
      # creates 10 break points for labels
      breaks = scales::pretty_breaks(n = 10),
      # changes the format to be dollars, without cents, scaled to be in billions
      labels = scales::dollar_format(
        prefix = "$",
        scale = (1e-6),
        largest_with_cents = 1,
      ), 
      limits = c(y_minimum, y_maximum*1.2),
      # defines the right side y-axis as a transformation of the left side axis, maximum UAAL = 100%, sets the breaks, labels
      sec.axis = ggplot2::sec_axis(
        ~ . / (y_maximum / 100),
        breaks = scales::pretty_breaks(n = 10),
        name = "Funded Ratio",
        #set limits
        labels = function(b) {
          paste0(round(b, 0), "%")
        }
      ),
      # removes the extra space so the fill is at the origin
      expand = c(0, 0)
    )+
    geom_hline(yintercept=0, linetype="solid", color = "black", size = 0.5)+
   ##Adding titles & caption
    labs(title = paste(title), 
         caption = ifelse(isTRUE(caption),paste("reason.org/pensions"),paste(""))
    )+
    ggplot2::theme(axis.ticks = if(isFALSE(ticks)){ggplot2::element_blank()}else{ggplot2::element_line()}
                   )+
   # coord_cartesian(ylim=(c(y_minimum, y_maximum*1.2)))+##Added limits
    coord_cartesian(expand = FALSE, #turn off axis expansion (padding)
                    xlim = c(2001, 2019), ylim = c(y_minimum, y_maximum*1.2))+ #manually set limits
    # sets the x-axis scale
    ggplot2::scale_x_continuous(breaks = round(seq(min(graph$year), max(graph$year), by = 2), 1),
                                expand = c(0, 0)) +#Added blanck ticks to x-axis
    
    ggplot2::theme(legend.position = "none")+
    ggplot2::theme(text = element_text(family = paste(font), size = 9))+ 
    ##Adding Gridlines
    ggplot2::theme(panel.grid.major.y = element_line(colour= ifelse(isTRUE(grid), 
                           paste(palette_reason$SpaceGrey),"white"),size = (1)))
}
##Plot graph
debt.plot  <- debtPlot(PERSI.debt,font = "Calibri")
savePlot(debt.plot, source = "Source: PIP", save_filepath = "/Users/anilniraula/Downloads/test.png",
         width_pixels = 600, height_pixels = 400)
#With Title, caption and grid
debtPlot(PERSI.debt, "Idaho PERS Pension Debt", caption = TRUE, grid = TRUE, ticks = TRUE, font = "Verdana")
#debtPlot(PERSI.debt, caption = F, grid = F, ticks = T)

############

#https://github.com/bbc/bbplot/blob/master/R/finalise_plot.R
#save_plot <- function (plot_grid, width, height, save_filepath) {
#  grid::grid.draw(plot_grid)
#  #save it
#  ggplot2::ggsave(filename = save_filepath,
#                  plot=plot_grid, width=(width/72), height=(height/72),  bg="white")
#}
#save_plot(plot1, 600, 400, "/users/Anil/downlaods")
####
