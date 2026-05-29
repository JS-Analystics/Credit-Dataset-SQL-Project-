The Dataset Used for this Project can be found on Kaggle by "credit_risk_dataset".

As mentioned before, I was restricted to only use SQL for this project, wherefore, the usage of linear regressions with significance tests was too
extensive for this project.

The challenge was that Credits/Loans were given to clients and that the hypothetical management suspected an inefficient asigning of interest rate
and if the credit should be issued at all given the default risk. The rule, by which Default risk has been issued so far was not revealed.

Clients were sorted into different Default Risk Groups, and first I have shown that the allocation in those groups is not correspondant with the correlation
to the client actually defaulting and the given parameter.

So I have decided to develope a new system to assign clients to a credit default risk group. This is what I did:
  1) I normalized the data using the log function
  2) I standardized the data
  3) I determined the default risk using the Pearson Correlation Koefficient per variable*
  4) I assigned the weight of each variable according to the default risk given the Pearson Correlation Koefficient
  5) The standardized variable was assigned a weight constant.
  6) The Group Limits were set such that the clients were distributed standard normally by their scoring value among all classes
  7) Since no time of default was given in the dataset, it was assumed that each defaulting client defaults at exactly half of his/her credit duration
  8) Using (7), a new interest rate could be determined such that the credits that were fully paid back cancel out the default risk of the credits
     that could only be partially paid back

*The Pearson Correlation Koefficient only measures how clear a correlation is and wether it is positive or negative, it does not measure by how much A increases
/ decreases if B increases / decreases. This would be the Beta Koefficient of an OLS Regression. Given that I could only use SQL as a tool, I was limited
in which statistical measures I could be using. Therefore, I decided to use the Pearson Correlation Coefficient. The OLS Regression would have been better,
if I could have used Python for this project I would have chosen that tool.
