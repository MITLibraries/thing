require 'test_helper'
require 'minitest/mock'

class FilenameNormalizerTest < ActiveSupport::TestCase
  test 'normalizes decomposed unicode to precomposed' do
    decomposed_filename = "sald\u0069\u0301as_thesis.pdf"
    assert_equal "sald\u00EDas_thesis.pdf", FilenameNormalizer.sanitize_filename(decomposed_filename)
  end

  test 'removes zero-width spaces from filenames' do
    assert_equal 'Liang-thesis.pdf', FilenameNormalizer.sanitize_filename("Liang-thesis\u200B.pdf")
  end

  test 'replaces en-dashes with hyphens' do
    assert_equal 'Siddiqui-sameed-thesis.pdf',
                 FilenameNormalizer.sanitize_filename("Siddiqui\u2013sameed-thesis.pdf")
  end

  test 'preserves safe precomposed accented characters' do
    %w[garcía_thesis.pdf strømstad_thesis.pdf MillánBarea_thesis.pdf].each do |filename|
      assert_equal filename, FilenameNormalizer.sanitize_filename(filename)
    end
  end

  test 'normalizes standalone blobs created for direct upload' do
    blob = create_blob("saldi\u0301as\u2013thesis\u200B.pdf")

    assert_empty blob.attachments
    assert_equal "sald\u00EDas-thesis.pdf", blob.reload[:filename]
  end

  test 'normalizes direct blob renames' do
    blob = create_blob('original.pdf')
    blob.update!(filename: "saldi\u0301as\u2013thesis\u200B.pdf")

    assert_equal "sald\u00EDas-thesis.pdf", blob.reload[:filename]
  end

  test 'normalization does not persist a filename when blob validation fails' do
    blob = create_blob('original.pdf')

    assert_not blob.update(filename: "renamed\u200B.pdf", service_name: nil)
    assert_equal 'renamed.pdf', blob[:filename]
    assert_equal 'original.pdf', blob.reload[:filename]
  end

  test 'does not normalize unchanged filenames on unrelated updates' do
    blob = create_blob('original.pdf')

    # Flunk test if sanitize_filename is called
    FilenameNormalizer.stub(:sanitize_filename, ->(*) { flunk 'Unchanged filename was normalized' }) do
      assert blob.update(metadata: { reviewed: true })
    end
  end

  private

  def create_blob(filename)
    ActiveStorage::Blob.create_before_direct_upload!(filename: filename, byte_size: 1,
                                                     checksum: Digest::MD5.base64digest('a'),
                                                     content_type: 'application/pdf')
  end
end
