# Windows Version 2009

>## Edge Optimizations
>
>### We now support a few optimizations for the New Edge
>
>***Warning*** - This optimization is not included in the "Optimizations" Parameter when "All" is selected. It specifically has to be called by passing in `-Optimizations Edge, <other optimizations>`

EdgeSettings.json

- BackgroundModeEnabled
- HideFirstRunExperience
- HideInternetExplorerRedirectUXForIncompatibleSitesEnabled
- ShowRecommendationsEnabled
- NotifyDisabledIEOptions
- DefaultAssociationsConfiguration
  - When setting this optimization, the *DefaultAssociationsConfiguration.xml* file will be copied to *c:\Windows\System32\defaultassociations.xml*.
  - By default, the associations are
    - html
    - htm
    - http
    - https
    - pdf
