require 'spec_helper'

describe Horza::DependencyLoading do
  
  before(:each) do 
    Horza.constant_file_paths += ["spec"] 
    ActiveSupport::Dependencies.autoload_paths += ["spec"] 
  end

  after(:each) do 
    Horza.clear_constant_file_paths
    ActiveSupport::Dependencies.autoload_paths.clear
  end

  describe "::resolve_dependency" do
    
    it "resolves constant for matching file" do
      const = Horza::DependencyLoading.resolve_dependency("test_employer")
      expect(const.name).to eq "TestConstants::TestEmployer"
    end

    it "raises if #constant_file_paths is empty" do
      Horza.clear_constant_file_paths

      expect { Horza::DependencyLoading.resolve_dependency("test_employer") }.to raise_error(ArgumentError)
    end

    it "raises if #constant_file_paths has nested directory paths" do
      Horza.constant_file_paths += ["spec/test_constants"]

      expect { Horza::DependencyLoading.resolve_dependency("test_employer") }.to raise_error
    end

    it "returns constant if already loaded" do
      Object.const_set(:A, Class.new)

      constant = Horza::DependencyLoading.resolve_dependency("a")
      expect(constant).to eq A
  
      Object.send(:remove_const, :A)
    end

    context "finds multiple matched constant_file_paths" do

      it "resolves constant for first matched file_path" do
        
        with_clashing_file do
          const = Horza::DependencyLoading.resolve_dependency("test_employer")
          expect(const.name).to eq "TestEmployer"
        end

      end
    end
  end
  
  describe "::search_for_file" do
    context "constant_file_paths are given" do
      it "returns file path if matched" do
        file_path = Horza::DependencyLoading.search_for_file("test_employer")
        expect(file_path).to eq "spec/test_constants/test_employer.rb"
      end

      it "raises if file path is not matched" do
        expect { Horza::DependencyLoading.search_for_file("employer") }.to raise_error(Horza::DependencyLoading::MissingFile)
      end
    end
  end


  describe "::constant_name_for_path" do
    it "returns a loadable constant name for file path" do
      name = Horza::DependencyLoading.constant_name_for_path("spec/test_constants/any_constant.rb")
      
      expect(name).to eq ["TestConstants::AnyConstant"]
    end
  end

  def with_clashing_file
    file_name = "spec/test_employer.rb"
    
    File.open(file_name, "w+") do |f| 
      f.write("class TestEmployer;end")  
    end

    yield

    FileUtils.rm(file_name)
  end
end