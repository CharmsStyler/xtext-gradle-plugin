package org.xtext.gradle.test

import org.junit.Test

//TODO use a different language than Xtend
class BuildingAPlainLanguageProject extends AbstractIntegrationTest {

	override setup() {
		super.setup
		buildFile << '''
			apply plugin: 'org.xtext.builder'

			configurations {
				compile
			}

			dependencies {
				compile 'org.eclipse.xtend:org.eclipse.xtend.lib:«xtextVersion»'
				xtextLanguages 'org.eclipse.xtend:org.eclipse.xtend.core:«xtextVersion»'
			}

			xtext {
				version = '«xtextVersion»'
				languages {
					xtend {
						setup = 'org.eclipse.xtend.core.XtendStandaloneSetup'
					}
				}
				sourceSets {
					main {
						srcDir 'src/main/xtend'
					}
				}
			}

			generateXtext.classpath = configurations.compile
		'''
	}

	@Test
	def theGeneratorShouldRunOnValidInput() {
		file('src/main/xtend/HelloWorld.xtend').content = '''
			class HelloWorld {}
		'''

		build("generateXtext")

		file('build/xtend/main/HelloWorld.java').shouldExist
		file('build/xtend/main/.HelloWorld.java._trace').shouldExist
	}

	@Test
	def theGeneratorShouldNotRunWhenAllFilesAreUpToDate() {
		file('src/main/xtend/HelloWorld.xtend').content = '''
			class HelloWorld {}
		'''

		build("generateXtext")
		val secondResult = build("generateXtext")
		secondResult.xtextTask.shouldBeUpToDate
	}

	@Test
	def theGeneratorShouldOnlyRunForAffectedFiles() {
		val upStream = createFile('src/main/xtend/UpStream.xtend', '''
			class UpStream {}
		''')
		createFile('src/main/xtend/DownStream.xtend', '''
			class DownStream {
				UpStream upStream
			}
		''')
		createFile('src/main/xtend/Unrelated.xtend', '''
			class Unrelated {}
		''')
		build("generateXtext")
		val snapshot = snapshot(projectDir)

		upStream.content = '''
			class UpStream {
				def void foo() {}
			}
		'''
		build("generateXtext")

		snapshot.assertChangedClasses("UpStream", "DownStream")
	}

	@Test
	def void generateOnceFoldersAreNotCleanedByCleanBuilds() {
		buildFile << '''xtext.languages.xtend.generator.outlet.cleanAutomatically = false'''
		file('src/main/java/com/example/HelloWorld.xtend').content = '''
			package com.example
			class HelloWorld {}
		'''
		val staleFile = file('build/xtend/main/com/example/Foo.java')
		staleFile.content = '''
			package com.example;
			public class Foo {}
		'''

		// when
		build('generateXtext')

		// then
		staleFile.shouldExist
	}

	@Test
	def void generateOnceFoldersAreNotCleanedByGradleClean() {
		buildFile << '''xtext.languages.xtend.generator.outlet.cleanAutomatically = false'''
		file('src/main/java/com/example/HelloWorld.xtend').content = '''
			package com.example
			class HelloWorld {}
		'''
		val staleFile = file('build/xtend/main/com/example/Foo.java')
		staleFile.content = '''
			package com.example;
			public class Foo {}
		'''

		// when
		build('cleanGenerateXtext')

		// then
		staleFile.shouldExist
	}
}