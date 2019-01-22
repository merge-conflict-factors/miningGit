# miningGit

The miningGit script is part of an empirical study infrastructure that aims to analyze merge conflict predictors.

More information here: https://merge-conflict-factors.github.io/merge-conflict-factors/

The mining script retrieves a list of merge commits and their parents. Then reproduces the merge scenario and check whether the merge resulted in conflicts, collect a list of conflicting files list, and compute the number of conflicts. Subsequently, it extracts the list of file names changed
(edited, added, or removed) by all revisions between a parent (left or right) and a base revision of a merge scenario. The changes associated with these files is what constitutes a contribution. 

To run the mining script:

*******Install all dependencies
1) To install the bundler to manage all dependencies, open a terminal window and run this command: gem install bundler.
2) To install all dependencies specified on the Gemfile: bundle install.

*******Configure projectsList file

1) The projectsList file contains all projects selected to compose the study sample. Thus, each line of this file should be set with a project identifier by using the following pattern:  "loginUser1/repoName1". For instance, this identifier represents the git repository located on https://github.com/loginUser1/repoName1.
2) Run the MainAnalysisProjects.rb script: ruby MainAnalysisProjects.rb

As output, this script will generate for each project that composes the sample, a file named  xx_MergeScenarioList.csv (xx means the project (s) name (s) used to compose the sample), with the following columns: 

- mergeCommitId: merge commit hash
- isMergeConflicting: true or false
- conflictingFiles: a list of the files with at least one conflict after merge replay
- parent1Id: left parent hash
- parent1Files: Left parent contribution
- parent2Id: left parent hash
- parent2Files: right parent contribution
- ancestorId: the common ancestor hash
- numberOfConflicts: the total number of conflict after merge replay
