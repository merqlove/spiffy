require "github/markup"
require "redcarpet"
require "haml"
require "pdfkit"

module Spiffy
  def self.markup_to_html(markup_file, css_file: nil, template_file: nil, pdf: false)
    markup_file_name = File.basename(markup_file, ".*")
    markup = File.open(markup_file, "r:UTF-8", &:read)

    html = Redcarpet::Markdown.new(Redcarpet::Render::HTML, tables: true).render(markup)
    
    if css_file
      css = File.open(css_file, "r:UTF-8", &:read)
    end

    if template_file
      template_ext = File.extname(template_file)
      template = File.open(template_file, "r:UTF-8", &:read)
      html = case template_ext
             when ".erb"
               ERB.new(template).result { |section| case section; when :css; css; when :body, nil; html; end }
             when ".haml"
               Haml::Engine.new(template).render { |section| case section; when :css; css; when :body, nil; html; end }
             else
               raise "Template file #{template_file} unsupported. Only .erb or .haml are supported."
             end
    end

    html_file = "#{markup_file_name}.html"
    File.open(html_file, "w:UTF-8") { |f| f.write(html) }

    return unless pdf
    pdf_file = "#{markup_file_name}.pdf"
    pdf = PDFKit.new(html)
    pdf.stylesheets << css_file if css_file
    pdf.to_file(pdf_file)
  end
end
