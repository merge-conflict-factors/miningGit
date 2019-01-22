require 'require_all'
require_all './Repository'

class GitProject

	def initialize(project, localPath, pathResults)
		@projetcName = project.split("/")[1].gsub("\"","")
		@pathClone = cloneProjectLocally(project, localPath)
		@mergeScenarios = Array.new
		getMergesScenariosByProject(localPath, pathResults)
	end


	def getPathClone()
		@pathClone
	end

	def getProjectName()
		@projetcName
	end

	def getMergeScenarios()
		@mergeScenarios
	end

	

	def cloneProjectLocally(project, localPath)
		Dir.chdir localPath
		if File.directory?("localProject")
			#delete = %x(rd /s /q localProject) #windows
			delete = %x(rm -rf localProject) # lixun usar rm -rf localProject
			puts "local was deleted before clonning" #debugging...
		end
		clone = %x(git clone https://github.com/#{project} localProject)
		Dir.chdir "localProject"
		return Dir.pwd
	end

	def deleteProject()
		Dir.chdir getLocalPath()
		#delete = %x(rd /s /q localProject) #windows
		delete = %x(rm -rf localProject) #linux usar: rm -rf localProject
	end

	def getMergesScenariosByProject(localPath, pathResults)
		Dir.chdir getPathClone()
		merges = %x(git log --pretty=format:'%H' --merges)
		merges.each_line do |mergeScenario|
			parents = getParentsMerge(mergeScenario.gsub("\n","").gsub("\'",""))
			ancestor = %x(git merge-base #{parents[0]} #{parents[1]}).gsub("\r","").gsub("\n","")
			# Remove fastforward merges before adding to the list
			if (!parents[0].eql? ancestor and !parents[1].eql? ancestor)
				mergeContributionsData = getMergeContributions(mergeScenario.gsub("\n", "").gsub("\'", ""), parents[0], parents[1], ancestor).split(",")
				leftContribution = mergeContributionsData[0]
				rightContribution = mergeContributionsData[1]

				# Remove other not focused merges in this study (i.e., nested pull request without changes)
				if (!leftContribution.eql?("[]") and !rightContribution.eql?("[]") )
					mergeScenarioObj = MergeScenario.new(mergeScenario.gsub("\n", "").gsub("\'", ""), parents[0], parents[1], ancestor)
					@mergeScenarios.push(mergeScenarioObj)
				end
			end
		end

		#generate summary of mergeScenario list
		totalMerges = merges.split("\n").length
  	totalFastFowardMerges = totalMerges - getMergeScenarios.length
		File.open(localPath+pathResults+"Summary_MergesByProject.csv", 'a') do |f2|
			if (File.size(localPath+pathResults+"Summary_MergesByProject.csv") == 0)
				f2.puts "project,totalMerges,totalFastFowardMerges,totalOtherMerges"
			end
			f2.puts "#{getProjectName},#{totalMerges},#{totalFastFowardMerges},#{getMergeScenarios.length}"
		end
	end

	
	def getParentsMerge(commit)
		parentsCommit = Array.new
		commitParent = %x(git cat-file -p #{commit})
		commitParent.each_line do |line|
			if(line.include?('author'))
				break
			end
			if(line.include?('parent'))
				commitSHA = line.partition('parent ').last.gsub('\n','').gsub(' ','').gsub('\r','')
				parentsCommit.push(commitSHA[0..39].to_s)
			end
		end

		if (parentsCommit.size > 1)
			return parentsCommit
		else
			return nil
		end
	end

	def generateMergeScenarioList(projectName, localPath, pathResults)

		dataList = []
		mergeCommitParents = getMergeScenarios
		mergeCommitParents.each do |mergeParents|
				mergeCommitID = mergeParents.getMergeCommit()
				left = mergeParents.getLeft()
				right = mergeParents.getRight()
				ancestor = mergeParents.getAncestor()
				mergeConflictsData = getMergeInfoAboutConflicts(mergeCommitID, left, right).split(",")
				mergeContributionsData = getMergeContributions(mergeCommitID, left, right, ancestor).split(",")
				mergeCommitId = mergeCommitID
				isMergeConflicting = mergeConflictsData[0]
				conflictingFiles = mergeConflictsData[1]
				parent1Id = left
				parent1Files = mergeContributionsData[0]
				parent2Id = right
				parent2Files = mergeContributionsData[1]
				ancestorId = ancestor
				numberOfConflicts = mergeConflictsData[2]
				data = mergeCommitId+","+isMergeConflicting+","+conflictingFiles+","+parent1Id+","+parent1Files+","+parent2Id+","+parent2Files+","+ancestorId+","+numberOfConflicts
				dataList.push(data.gsub("\n", ""))
		end
		count = 0 #debugging
		File.open(localPath+pathResults+projectName+"_MergeScenarioList.csv", 'w') do |file|
			file.puts "mergeCommitId,isMergeConflicting,conflictingFiles,parent1Id,parent1Files,parent2Id,parent2Files,ancestorId,numberOfConflicts"
			dataList.each do |dataMerge|
				file.puts "#{dataMerge}"
				count+=1
			end
			puts "Ending execution: Projeto #{projectName} - Merges = #{count}" #debugging...
			# Generate resulting project list
			File.open(localPath+pathResults+"projectList.csv", 'a') do |f2|
				f2.puts "#{getProjectName}"
			end
		end

		return dataList

	end



	def getMergeInfoAboutConflicts(mergeCommitID, left, right)
		Dir.chdir getPathClone
		branchName = %x(git branch).split(" ")[1].gsub("\n","") # get branch name
		%x(git reset --hard #{left})
		%x(git clean -f)
		%x(git checkout -b new #{right})
		#%x(git checkout master)
		%x(git checkout #{branchName})
		%x(git merge new)

		conflictingFiles = %x(git diff --name-only --diff-filter=U).split("\n")
		isMergeConflicting = false

		# get "conflict occurrence" response variable
		if (conflictingFiles.length > 0) # conflict
    	isMergeConflicting = true
		end

		totalConflicts = 0
		conflictingFiles.each do |conflictingFile|
			x = '=======' # Other conflict markers can be used. We chose this one.
			parcialTotal = 0
			parcialTmp = %x(git grep -c #{x} #{conflictingFile})#.split(":")[1].gsub("\n","").to_i
			if (parcialTmp.length ==0)
				parcialTotal = 1
			else
				parcialTotal = %x(git grep -c #{x} #{conflictingFile}).split(":")[1].gsub("\n","").to_i
			end
			totalConflicts = totalConflicts + parcialTotal
		end
		dataInfoMerges = isMergeConflicting.to_s+","+conflictingFiles.to_s.gsub("\"","").gsub(",","@")+","+totalConflicts.to_s

		#delete without merge
		%x(git branch -D new)

		return dataInfoMerges

	end

	def getMergeContributions(mergeCommitID, left, right, ancestor)
		Dir.chdir getPathClone
		dataListLeft = []
		dataListRight = []
		#use --name-status instead of --name-only if you want to see the status (i.e., deleted (D), added (D), and modified (M))
		leftFiles = %x(git diff --name-status #{left} ^#{ancestor}).split("\n").uniq
		leftFiles.each do |line|
			if (line.split(" ").size == 3) # renamed file - i.e., "R100	app/assets/stylesheets/modules/markdown_panel.css.scss	app/assets/stylesheets/components/markdown.scss"
				fileName = line.split(" ")[2]
				dataListLeft.push(fileName)
			else # Added, Deleted or Modified i.e. "M	Gemfile.lock"
				fileName = line.split(" ")[1]
				dataListLeft.push(fileName)
			end
		end

		rightFiles = %x(git diff --name-status #{right} ^#{ancestor}).split("\n").uniq
		rightFiles.each do |line|
			if (line.split(" ").size == 3) # renamed file - i.e. "R100	app/assets/stylesheets/modules/markdown_panel.css.scss	app/assets/stylesheets/components/markdown.scss"
				fileName = line.split(" ")[2]
				dataListRight.push(fileName)
			else # Added, Deleted or Modified i.e. "M	Gemfile.lock"
				fileName = line.split(" ")[1]
				dataListRight.push(fileName)
			end
		end

		mergeContributions = dataListLeft.to_s.gsub("\"","").gsub(",","@")+","+dataListRight.to_s.gsub("\"","").gsub(",","@")

		return mergeContributions
	end


end
