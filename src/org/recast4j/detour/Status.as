/*
Copyright (c) 2009-2010 Mikko Mononen memon@inside.org
Recast4J Copyright (c) 2015 Piotr Piastucki piotr@jtilia.org

This software is provided 'as-is', without any express or implied
warranty.  In no event will the authors be held liable for any damages
arising from the use of this software.
Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:
1. The origin of this software must not be misrepresented; you must not
 claim that you wrote the original software. If you use this software
 in a product, an acknowledgment in the product documentation would be
 appreciated but is not required.
2. Altered source versions must be plainly marked as such, and must not be
 misrepresented as being the original software.
3. This notice may not be removed or altered from any source distribution.
*/
package org.recast4j.detour {
public class Status {
	
	public static const FAILURE:int = 0;
	public static const SUCCSESS:int = 1;
	public static const IN_PROGRESS:int = 2;
	public static const PARTIAL_RESULT:int=3;
	
	public static function isFailed(status:int):Boolean {
		return status == FAILURE;
	}

	public static function isInProgress(status:int):Boolean {
		return status == IN_PROGRESS;
	}

	public static function isSuccess(status:int):Boolean {
		return status == Status.SUCCSESS||status==Status.PARTIAL_RESULT;
	}
	
	public static function isPartial(status:int):Boolean {
		return status==Status.PARTIAL_RESULT;
	}
}
}