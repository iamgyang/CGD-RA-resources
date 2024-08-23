program define clean_country_name
    // Declare the input variable as an argument
    syntax varlist(min=1 max=1)
    
    // Local variables for special characters and their replacements
    local special_chars "é è ê ë á à â ä î ï í ì ô ö ò û ü ù ñ ç œ æ ß"
    local replacements "e e e e a a a a i i i i o o o u u u n c oe ae ss"
    
    // Create a new variable to store the cleaned country name
    gen cleaned_country_name = `varlist'
    
    // Loop over each special character and replace it with the corresponding replacement
    forval i = 1/`=wordcount("`special_chars'")' {
        local sc = word("`special_chars'", `i')
        local rep = word("`replacements'", `i')
        replace cleaned_country_name = subinstr(cleaned_country_name, "`sc'", "`rep'", .)
    }
    
    // Optionally remove any remaining non-alphanumeric characters
    replace cleaned_country_name = regexr(cleaned_country_name, "[^a-zA-Z0-9 ]", "")
    
end
