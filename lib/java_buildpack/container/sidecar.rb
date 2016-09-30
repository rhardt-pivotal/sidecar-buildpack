# Encoding: utf-8
# Cloud Foundry Java Buildpack
# Copyright 2013-2016 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'java_buildpack/component/base_component'
require 'java_buildpack/container'
require 'java_buildpack/util/dash_case'
require 'java_buildpack/util/java_main_utils'
require 'java_buildpack/util/qualify_path'
require 'java_buildpack/util/spring_boot_utils'
require 'yaml'
require 'json'

module JavaBuildpack
  module Container

    # Encapsulates the detect, compile, and release functionality for applications running a simple Java +main()+
    # method. This isn't a _container_ in the traditional sense, but contains the functionality to manage the lifecycle
    # of Java +main()+ applications.
    class Sidecar < JavaBuildpack::Component::BaseComponent
      include JavaBuildpack::Util

      # Creates an instance
      #
      # @param [Hash] context a collection of utilities used the component
      def initialize(context)
        super(context)
        @spring_boot_utils = JavaBuildpack::Util::SpringBootUtils.new
      end

      # (see JavaBuildpack::Component::BaseComponent#detect)
      def detect
        "Sidecar-buildpack"
      end

      # (see JavaBuildpack::Component::BaseComponent#compile)
      def compile
        @droplet.copy_resources
        #return unless @spring_boot_utils.is?(@application)
        #@droplet.additional_libraries.link_to(@spring_boot_utils.lib(@droplet))
      end

      SIDECAR_RELEASE = "sidecar_release.out"
      LAST_PACK_RELEASE = "last_pack_release.out"
      FINAL_RELEASE = "final_release.out"

      def post_compile


        puts("SIDECAR POST COMPILE")
        app_dir = @application.root

        sidecar_release = YAML.load_file(File.join(app_dir, SIDECAR_RELEASE))
        pack_release = YAML.load_file(File.join(app_dir, LAST_PACK_RELEASE))

        puts pack_release.to_yaml

        puts Dir.entries(app_dir)

        puts ev




        sidecar_command = "#!/usr/bin/env bash\n\n"+sidecar_release['default_process_types']['web']
        pack_command = "#!/usr/bin/env bash\n\n"+pack_release['default_process_types']['web']

        pack_release['default_process_types']['web']="./run_all.sh"
        File.open(File.join(app_dir, "final_release.out"), 'w') {|f| f.write pack_release.to_yaml }

        File.open(File.join(app_dir, "run_sidecar.sh"), 'w') { |file| file.write(sidecar_command)}
        File.open(File.join(app_dir, "run_pack.sh"), 'w') { |file| file.write(pack_command)}
        File.chmod(0755, File.join(app_dir, "run_sidecar.sh"))
        File.chmod(0755, File.join(app_dir, "run_pack.sh"))

        @droplet.copy_resource(file_name="run_all.sh", target_directory=app_dir)
        File.chmod(0755, File.join(app_dir, "run_all.sh"))


      end

      # (see JavaBuildpack::Component::BaseComponent#release)
      def release
        manifest_class_path.each { |path| @droplet.additional_libraries << path }

        if @spring_boot_utils.is?(@application)
          @droplet.environment_variables.add_environment_variable 'SERVER_PORT', '$PORT'
        else
          @droplet.additional_libraries.insert 0, @application.root
        end

        #classpath = @spring_boot_utils.is?(@application) ? '-cp $PWD/.' : @droplet.additional_libraries.as_classpath
        release_text #(classpath)
      end

      private

      ARGUMENTS_PROPERTY = 'arguments'.freeze

      CLASS_PATH_PROPERTY = 'Class-Path'.freeze

      private_constant :ARGUMENTS_PROPERTY, :CLASS_PATH_PROPERTY

      def release_text
        [
          @droplet.java_opts.as_env_var,
          '&&',
          @droplet.environment_variables.as_env_vars,
          'eval',
          'exec',
          "#{qualify_path @droplet.java_home.root, @droplet.root}/bin/java",
          '$JAVA_OPTS',
          '-jar',
          "#{qualify_path @droplet.java_home.root, @droplet.root}/../sidecar/sidecar.jar",
          arguments
        ].flatten.compact.join(' ')
      end

      def arguments
        @configuration[ARGUMENTS_PROPERTY]
      end

      def main_class
        JavaBuildpack::Util::JavaMainUtils.main_class(@application, @configuration)
      end

      def manifest_class_path
        values = JavaBuildpack::Util::JavaMainUtils.manifest(@application)[CLASS_PATH_PROPERTY]
        values.nil? ? [] : values.split(' ').map { |value| @droplet.root + value }
      end

    end

  end
end
