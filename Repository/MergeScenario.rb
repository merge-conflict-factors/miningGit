class MergeScenario

	def initialize(mergeCommitSHA, leftSHA, rightSHA, ancestorSHA)
		@mergeCommit = mergeCommitSHA
		@left = leftSHA
		@right = rightSHA
		@ancestor = ancestorSHA
	end

	def getMergeCommit()
		@mergeCommit
	end
	
	def getLeft()
		@left
	end
		
	def getRight()
		@right
	end

	def getAncestor()
		@ancestor
	end

end