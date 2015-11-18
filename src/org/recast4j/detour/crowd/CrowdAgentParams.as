package org.recast4j.detour.crowd {
/// Configuration parameters for a crowd agent.
/// @ingroup crowd
public class CrowdAgentParams
{
	var radius:Number;						///< Agent radius. [Limit: >= 0]
	var height:Number;						///< Agent height. [Limit: > 0]
	var maxAcceleration:Number;				///< Maximum allowed acceleration. [Limit: >= 0]
	var maxSpeed:Number;						///< Maximum allowed speed. [Limit: >= 0]

	/// Defines how close a collision element must be before it is considered for steering behaviors. [Limits: > 0]
	var collisionQueryRange:Number;

	var pathOptimizationRange:Number;		///< The path visibility optimization range. [Limit: > 0]

	/// How aggresive the agent manager should be at avoiding collisions with this agent. [Limit: >= 0]
	var separationWeight:Number;

	/// Flags that impact steering behavior. (See: #UpdateFlags)
	var updateFlags:int;

	/// The index of the avoidance configuration to use for the agent. 
	/// [Limits: 0 <= value <= #DT_CROWD_MAX_OBSTAVOIDANCE_PARAMS]
	var obstacleAvoidanceType:int;	

	/// The index of the query filter used by this agent.
	var queryFilterType:int;

	/// User defined data attached to the agent.
	var userData:Object;
}
}