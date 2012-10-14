require "motion_require/version"
require "motion_require/dependency_graph"

module MotionRequire
  module ConfigTask
    def auto_require
      MotionRequire::DependencyGraph.build(self)
    end
  end
end

Motion::Project::Config.send(:include, MotionRequire::ConfigTask)
