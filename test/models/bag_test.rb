require 'test_helper'

class BagTest < ActiveSupport::TestCase
  include Checksums

  test 'creates bag declaration' do
    bag = Bag.new(theses(:published))
    assert_equal "BagIt-Version: 1.0\nTag-File-Character-Encoding: UTF-8", bag.bag_declaration
  end

  test 'bag declaration does not vary' do
    another_published_thesis = theses(:publication_review)
    another_published_thesis.dspace_handle = '1234.5678'
    another_published_thesis.save

    bag = Bag.new(theses(:published))
    another_bag = Bag.new(another_published_thesis)
    assert_equal bag.bag_declaration, another_bag.bag_declaration
  end

  test 'creates manifest' do
    thesis = theses(:published)
    checksums = []
    checksums << "#{base64_to_hex(thesis.files.first.checksum)} data/a_pdf.pdf"
    checksums << "#{ArchivematicaMetadata.new(thesis).md5} data/metadata.csv"
    bag = Bag.new(thesis)
    assert_equal checksums.join("\n"), bag.manifest
  end

  test 'files in manifest are separated with newlines' do
    thesis = theses(:published)
    file = Rails.root.join('test', 'fixtures', 'files', 'registrar_data_small_sample.csv')
    thesis.files.attach(io: File.open(file), filename: 'registrar_data_small_sample.csv')
    assert thesis.files.length > 1

    bag = Bag.new(thesis)
    assert_includes bag.manifest, "\n"
  end

  test 'creates bag name' do
    bag = Bag.new(theses(:published))
    assert_equal '1234.5_6789-thesis', bag.bag_name
  end

  test 'data generates file location hash' do
    bag = Bag.new(theses(:published))
    expected = theses(:published).files.first.blob
    assert_equal expected, bag.data['data/a_pdf.pdf']
  end

  test 'data generates metadata file' do
    t = theses(:published)
    bag = Bag.new(t)
    expected = ArchivematicaMetadata.new(t).to_csv
    assert_equal expected, bag.data['data/metadata.csv']
  end

  test 'detects duplicate filenames' do
    # one file
    thesis = theses(:published)
    bag = Bag.new(thesis)
    assert_not bag.duplicate_filenames?

    # multiple files, no duplicate filenames
    file = Rails.root.join('test', 'fixtures', 'files', 'registrar_data_small_sample.csv')
    thesis.files.attach(io: File.open(file), filename: 'registrar_data_small_sample.csv')
    bag = Bag.new(thesis)
    assert_not bag.duplicate_filenames?

    # multiple files, duplicate filenames
    file = Rails.root.join('test', 'fixtures', 'files', 'a_pdf.pdf')
    thesis.files.attach(io: File.open(file), filename: 'a_pdf.pdf')
    assert_raises 'This thesis is not baggable' do
      bag = Bag.new(thesis)
    end
  end

  test 'raises exception if the thesis is not baggable' do
    # baggable thesis (files attached, DSpace handle, no duplicate filenames)
    thesis = theses(:published)
    assert_nothing_raised do
      Bag.new(thesis)
    end

    # unbaggable thesis (DSpace handle is nil)
    thesis.dspace_handle = nil
    thesis.save
    assert_raises 'This thesis is not baggable' do 
      Bag.new(thesis)
    end

    # unbaggable thesis (DSpace handle is an empty string)
    thesis.dspace_handle = ''
    thesis.save
    assert_raises 'This thesis is not baggable' do 
      Bag.new(thesis)
    end

    # unbaggable thesis (duplicate filenames)
    thesis.dspace_handle = '1234/5678'
    file = Rails.root.join('test', 'fixtures', 'files', 'a_pdf.pdf')
    thesis.files.attach(io: File.open(file), filename: 'a_pdf.pdf')
    thesis.save
    assert_raises 'This thesis is not baggable' do 
      Bag.new(thesis)
    end

    # unbaggable thesis (no files attached)
    thesis.files = nil
    thesis.save
    assert_raises 'This thesis is not baggable' do 
      Bag.new(thesis)
    end
  end
end
