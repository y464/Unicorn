// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/uni/license.d (BOOST ver. 1.0 license).

/**
 * The basic building blocks for a build.
 */
module uni.core.target;

import std.datetime : SysTime;
import std.file : getTimes;
import std.string : format;


/**
 * Holds all inspected files/targets for a build. The caching supplied
 * by this class helps with both speed and ease of use.
 */
final class Instance
{
private:
	Target[string] targets;

public:
	Target file(string name)
	{
		auto test = name in targets;
		if (test !is null) {
			return *test;
		}

		auto ret = new Target();
		ret.name = name;
		return targets[name] = ret;
	}

	Target fileNoRule(string name)
	{
		auto ret = file(name);
		if (ret.rule !is null) {
			auto str = format(
				"File \"%s\" already has a rule", name);
			throw new Exception(str);
		}

		return ret;
	}
}

/**
 * Most basic building block, represent a single file on the file
 * system. Can be used as a dependency and as a target to be built.
 */
final class Target
{
public:
	enum Status {
		FRESH,
		CHECKED,
		BUILDING,
		BUILT
	}

	alias Status.FRESH FRESH;
	alias Status.CHECKED CHECKED;
	alias Status.BUILDING BUILDING;
	alias Status.BUILT BUILT;

	/// What is the status of this target.
	/// Used to skip updating the date.
	Status status;

	/// Name, for file also actuall filename.
	string name;

	/// Rule to build this targe.
	Rule rule;

	/// Will be built, but if no rule and missing will be ignored.
	Target[] deps;

	/// Cached last modified time.
	SysTime mod;

public:
	/// Updates the @mod field to the files last modified time.
	void updateTime()
	{
		// Somebody might have set a higher status.
		if (status <= FRESH) {
			status = CHECKED;
		}

		try {
			SysTime a;

			getTimes(name, a, mod);
		} catch (Exception e) {
			mod = SysTime.min;
		}
	}

	/**
	 * Called by the solver when, the target has been built.
	 */
	void built()
	{
		updateTime();
		status = BUILT;
	}
}

/**
 * Rule to be executed. Can be shared for multiple targets.
 */
final class Rule
{
public:
	/// To run be executed.
	string cmd;

	/// To be given to cmd.
	string[] args;

	/// Echoed to stdout.
	string print;

	/// Files needed directly to run this rule.
	Target[] input;

	/// When the rule is running these targets will be locked.
	Target[] outputs;
}
