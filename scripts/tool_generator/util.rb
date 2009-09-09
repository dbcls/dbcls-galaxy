def snake_to_upper_camel(str)
  str.gsub("_"){ " " }.gsub(/(\w)(\w*)/){ $1.upcase + $2 }
end
