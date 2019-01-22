require 'require_all'
require_all './Repository'

class MainAnalysisProjects

	def initialize(loginUser, passwordUser, pathResultsAllMerges, projectsList)
		@loginUser = loginUser
		@passwordUser = passwordUser
		@pathResultsAllMerges = pathResultsAllMerges
		@localPath = Dir.pwd
		Dir.chdir getLocalPath
		@projectsList = projectsList
	end

	def getLocalPath()
		@localPath
	end

	def getLoginUser()
		@loginUser
	end

	def getPasswordUser()
		@passwordUser
	end

	def getPathResultsAllMerges()
		@pathResultsAllMerges
	end

	def getProjectsList()
		@projectsList
	end

	def printStartAnalysis()
		puts "*************************************"
		puts "-------------------------------------"
		puts "####### START COMMITS SEARCH #######"
		puts "-------------------------------------"
		puts "*************************************"
	end

	def printProjectInformation (index, project)
		puts "Project [#{index}]: #{project}"
	end

	def printFinishAnalysis()
		puts "*************************************"
		puts "-------------------------------------"
		puts "####### FINISH COMMITS SEARCH #######"
		puts "-------------------------------------"
#		puts "*************************************"
	end

	def runAnalysis()
		printStartAnalysis()
		index = 1
		@projectsList.each do |project|
			printProjectInformation(index, project)
			# comment the following four lines if you just want to generate a random subset of merge scenarios
			mainGitProject = GitProject.new(project, getLocalPath, @pathResultsAllMerges)
			projectName = mainGitProject.getProjectName()
			puts "projectName = #{projectName}"		#debugging...
			allMerges = mainGitProject.generateMergeScenarioList(projectName,getLocalPath, getPathResultsAllMerges)

			index += 1
		end
		printFinishAnalysis()
	end

end

parameters = []
File.open("properties", "r") do |text|
	indexLine = 0
	text.each_line do |line|
		parameters[indexLine] = line[/\<(.*?)\>/, 1]
		indexLine += 1
	end
end

projectsList = []
File.open("projectsList", "r") do |text|
	indexLine = 0
	text.each_line do |line|
		projectsList[indexLine] = line[/\"(.*?)\"/, 1]
		indexLine += 1
	end
end

actualPath = Dir.pwd
#puts "actualPath = #{actualPath}"
project = MainAnalysisProjects.new(parameters[0], parameters[1], parameters[2], projectsList)

#debugging...
#puts "Project List[#{project.getProjectsList()}]"
#puts "Local Project[#{project.getLocalPath()}]"
#puts "Login User[#{project.getLoginUser()}]"
#puts "Password User[#{project.getPasswordUser()}]"
#puts "Path Resuts[#{project.getPathResults()}]"
# end debugging...

project.runAnalysis()

