module Microdata
# Class that parses itemprop elements
  class Itemprop

    NON_TEXTCONTENT_ELEMENTS = {
      'a' => 'href',        'area' => 'href',
      'audio' => 'src',     'embed' => 'src',
      'iframe' => 'src',    'img' => 'src',
      'link' => 'href',     'meta' => 'content',
      'object' => 'data',   'source' => 'src',
      'time' => 'datetime', 'track' => 'src',
      'video' => 'src'
    }

    URL_ATTRIBUTES = ['data', 'href', 'src']

    PRODUCT_PROPERTIES = {
      'priceCurrency' => 'content',
      'availability' => ['href', 'content'],
      'price' => 'content'
    }

    # A Hash representing the properties.
    # Hash is of the form {'property name' => 'value'}
    attr_reader :properties

    # Create a new Itemprop object
    # [element]  The itemprop element to be parsed
    # [page_url] The url of the page, including filename, used to form
    #            absolute urls
    def initialize(element, page_url=nil)
      @element, @page_url = element, page_url
      @properties = extract_properties
    end

    # Parse the element and return a hash representing the properties.
    # Hash is of the form {'property name' => 'value'}
    # [element]  The itemprop element to be parsed
    # [page_url] The url of the page, including filename, used to form
    #            absolute urls
    def self.parse(element, page_url=nil)
      self.new(element, page_url).properties
    end

  private
    def extract_properties
      prop_names = extract_property_names
      prop_names.each_with_object({}) do |name, memo|
        memo[name] = extract_property(name)
      end
    end

    # This returns an empty string if can't form a valid
    # absolute url as per the Microdata spec.
    def make_absolute_url(url)
      return url unless URI.parse(url).relative?
      begin
        URI.parse(@page_url).merge(url).to_s
      rescue URI::Error
        url
      end
    end

    def product_property?(property_name)
      PRODUCT_PROPERTIES.has_key?(property_name)
    end

    def non_textcontent_element?(element)
      NON_TEXTCONTENT_ELEMENTS.has_key?(element)
    end

    def url_attribute?(attribute)
      URL_ATTRIBUTES.include?(attribute)
    end

    def extract_property_names
      itemprop_attr = @element.attribute('itemprop')
      itemprop_attr ? itemprop_attr.value.split() : []
    end

    def resovle_attribute(element, property_name)
      NON_TEXTCONTENT_ELEMENTS[element] || PRODUCT_PROPERTIES[property_name]
    end

    def extract_attribute_value(element, *lookups)
      lookups.each do |attribute_name|
        if attribute = element.attribute(attribute_name)
          return attribute.value if attribute.value
        end
      end
      nil
    end

    def extract_property_value(property_name)
      element_name = @element.name
      attribute_name = resovle_attribute(element_name, property_name)
      if attribute_name
        if value = extract_attribute_value(@element, attribute_name)
          url_attribute?(attribute_name) ? make_absolute_url(value) : value
        else
          @element.inner_text.strip
        end
      else
        @element.inner_text.strip
      end
    end

    def extract_property(name)
      if @element.attribute('itemscope')
        Item.new(@element, @page_url)
      else
        extract_property_value(name)
      end
    end

  end
end
