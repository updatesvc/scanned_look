require 'sinatra'
require 'shotgun'
require 'fileutils'
require 'pdf-reader'

get "/" do
  erb :index
end

get "/download/:filename" do |filename|
  file_path = "#{Dir.pwd}/converted/#{filename}"
  content_type :pdf
  content = File.read file_path
  File.delete(file_path)
  content
end

post "/upload" do
  p "============ PARAMS ================"
  p params
  p params['myfile'][:type] == 'image/gif'
  p params['myfile'][:type] == 'application/pdf'


  tempfile = params['myfile'][:tempfile]
  filename = params['myfile'][:filename]
  filename.gsub!(/\s/,"") if /\s/.match(filename)
  FileUtils.copy(tempfile.path, "uploads/#{filename}")


  pages = PDF::Reader.new("uploads/#{filename}").page_count
  page_paths = []

  # "Scan" each page
  pages.times do |page|
    system("convert #{Dir.pwd}/uploads/#{filename}[#{page}] -mattecolor gray99 -frame 1x1+1 -colorspace gray \\( +clone -blur 0x1 \\) +swap -compose divide -resize 800 -composite -contrast-stretch 5%,0% -rotate #{rand*2 - 1} #{Dir.pwd}/converted/#{filename}-#{page}-scanned.pdf")
    page_paths << "#{Dir.pwd}/converted/#{filename}-#{page}-scanned.pdf"
  end

  # Combine into single PDF
  system("gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile=#{Dir.pwd}/converted/#{filename}-scanned.pdf #{page_paths.join(' ')}")

  # Delete original upload
  File.delete("#{Dir.pwd}/uploads/#{filename}")

  # Delete scanned pages
  pages.times do |page|
    File.delete("#{Dir.pwd}/converted/#{filename}-#{page}-scanned.pdf")
  end


  return "The file was successfully scanned! <a href='download/#{filename}-scanned.pdf'>Download!</a>"
end


# convert test.pdf -mattecolor gray99 -frame 1x1+1 -colorspace gray \( +clone -blur 0x1 \) +swap -compose divide -resize 800 -composite -contrast-stretch 5%,0% -rotate 1 as-scanned.jpg
# Merge PDFs in directory with ghostscript
# gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile=temp.pdf pdf1.pdf pdf2.pdf


__END__
@@index

<h1>Scanned Look</h1>
<form action="/upload" method="post" enctype="multipart/form-data">
  <input type="file" name="myfile">
  <input type="submit">
</form>

<h2>To Do:</h2>
<ul>
  <li>Check file type</li>
  <li>Delete files after download</li>
</ul>
